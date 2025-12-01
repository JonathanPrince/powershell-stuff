param(
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [int[]]$Ports = (1..1024),          # default Nmap port range
    [int]$Timeout = 200,                # ms per port (lightweight)
    [int]$Concurrency = 100             # limit parallel load
)

# Semaphore to throttle concurrency
$sem = [System.Threading.SemaphoreSlim]::new($Concurrency, $Concurrency)
$jobs = @()

Write-Host "Scanning $Target ..."

foreach ($port in $Ports) {
    $null = $sem.WaitAsync()
    
    $jobs += [System.Threading.Tasks.Task]::Run({
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $async = $client.BeginConnect($using:Target, $using:port, $null, $null)
            $success = $async.AsyncWaitHandle.WaitOne($using:Timeout)

            if ($success -and $client.Connected) {
                $client.EndConnect($async)
                [PSCustomObject]@{
                    Port  = $using:port
                    State = "Open"
                }
            }
        } catch {
            # ignored
        } finally {
            $client.Close()
            $using:sem.Release() | Out-Null
        }
    })
}

# Collect results
$results = [System.Threading.Tasks.Task]::WaitAll($jobs, 300000)  # 5 min max
$openPorts = $jobs | Where-Object { $_.Result -ne $null } | ForEach-Object { $_.Result }

Write-Host ""
Write-Host "Open ports on $Target:"
$openPorts | Sort-Object Port | Format-Table -AutoSize
