# scan.ps1  — PowerShell 5+ sem nmap
$port = 5432

# Lê hosts, remove vazios e comentários
$targets = Get-Content .\hosts.txt |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -and ($_ -notmatch '^\s*#') }

if (-not $targets) { throw "hosts.txt está vazio após limpeza." }

function Test-TcpPort {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Target,
    [int]$Port = 5432,
    [int]$TimeoutMs = 3000
  )
  $sw = [Diagnostics.Stopwatch]::StartNew()
  try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $ar  = $tcp.BeginConnect($Target, $Port, $null, $null)
    if ($ar.AsyncWaitHandle.WaitOne($TimeoutMs)) {
      $tcp.EndConnect($ar); $tcp.Close(); $sw.Stop()
      [pscustomobject]@{ Target=$Target; Port=$Port; Open=$true; TimeMs=$sw.ElapsedMilliseconds }
    } else {
      $tcp.Close()
      [pscustomobject]@{ Target=$Target; Port=$Port; Open=$false; TimeMs=$null }
    }
  } catch {
    [pscustomobject]@{ Target=$Target; Port=$Port; Open=$false; TimeMs=$null }
  }
}

# Executa
$results = foreach ($t in $targets) {
  Test-TcpPort -Target $t -Port $port -TimeoutMs 3000
}

# Saída
$results | Export-Csv -NoTypeInformation scan_5432_results.csv
$results | Where-Object Open | Format-Table -AutoSize
