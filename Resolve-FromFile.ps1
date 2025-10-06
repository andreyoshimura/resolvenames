param(
  [Parameter(Mandatory=$true)]
  [string]$File,
  [string]$OutputDir = ".",
  [string]$DnsServer
)

function Get-HostList {
  param([string]$Path)
  if (-not (Test-Path $Path)) { throw "Arquivo não encontrado: $Path" }
  Get-Content -Path $Path -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and ($_ -notmatch '^\s*[#;]') -and ($_ -notmatch '^\s*//') } |
    Sort-Object -Unique
}

function To-Punycode {
  param([string]$Name)
  try {
    $idn = [System.Globalization.IdnMapping]::new()
    $trailDot = $Name.EndsWith(".")
    $labels = $Name.TrimEnd(".").Split(".") | Where-Object { $_ }
    $ascii = ($labels | ForEach-Object { $idn.GetAscii($_) }) -join "."
    if ($trailDot) { "$ascii." } else { $ascii }
  } catch { $Name }
}

function Resolve-HostIPs {
  param([string]$Hostname,[string]$DnsServer)
  $out = @()
  $useResolve = Get-Command Resolve-DnsName -ErrorAction SilentlyContinue
  $name = To-Punycode $Hostname
  try {
    if ($useResolve) {
      $common = @{ Name=$name; ErrorAction='Stop'; DnsOnly=$true }
      if ($DnsServer) { $common.Server = $DnsServer }
      foreach ($t in 'A','AAAA') {
        try {
          $ips = Resolve-DnsName @common -Type $t |
            Where-Object { $_.Type -in 'A','AAAA' } |
            Select-Object -ExpandProperty IPAddress -ErrorAction SilentlyContinue |
            Sort-Object -Unique
          foreach ($ip in $ips) { $out += [pscustomobject]@{ Host=$Hostname; Type=$t; IP=$ip } }
        } catch { }
      }
    } else {
      $ips = [System.Net.Dns]::GetHostAddresses($name) |
             Select-Object -ExpandProperty IPAddressToString | Sort-Object -Unique
      foreach ($ip in $ips) {
        $fam = ([System.Net.IPAddress]::Parse($ip)).AddressFamily
        $t = if ($fam -eq 'InterNetworkV6') { 'AAAA' } else { 'A' }
        $out += [pscustomobject]@{ Host=$Hostname; Type=$t; IP=$ip }
      }
    }
    if (-not $out) { $out = @([pscustomobject]@{ Host=$Hostname; Type=''; IP='Erro: sem registros A/AAAA' }) }
  } catch {
    $out = @([pscustomobject]@{ Host=$Hostname; Type=''; IP=("Erro: " + $_.Exception.Message) })
  }
  return $out
}

# principal
$hosts = Get-HostList -Path $File
if (-not $hosts -or $hosts.Count -eq 0) { Write-Error "Lista de hosts vazia."; exit 1 }

$rows = @()
foreach ($h in $hosts) { $rows += Resolve-HostIPs -Hostname $h -DnsServer $DnsServer }

if (-not $rows -or $rows.Count -eq 0) { Write-Error "Nenhum resultado gerado."; exit 2 }

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$csvPath = Join-Path $OutputDir ("IPs_{0}.csv" -f $timestamp)

$rows | Format-Table -AutoSize
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "`nResultados salvos em: $csvPath"
