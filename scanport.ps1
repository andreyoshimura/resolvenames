$port = 5432
$results = foreach ($h in Get-Content hosts.txt) {
  $r = Test-NetConnection -ComputerName $h -Port $port -WarningAction SilentlyContinue
  [PSCustomObject]@{
    Host = $h
    Port = $port
    TcpTestSucceeded = $r.TcpTestSucceeded
    RoundtripTimeMs = $r.PingReplyDetails.RoundtripTime
  }
}
$results | Export-Csv -NoTypeInformation scan_5432_results.csv
$results | Where-Object { $_.TcpTestSucceeded } | Format-Table -AutoSize

