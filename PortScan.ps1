param(
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [int[]]$Ports = (1..1024),
    [int]$Timeout = 200,
    [int]$Concurrency = 100
)

# Create semaphore
$sem = New-Object System.Threading.SemaphoreSlim($Concurrency, $Concurrency)
$jobs = New-Object System.Collections.Generic.List[System.Threading.Tasks.Task]

Write-Host "Scanning $Target ..."

foreach ($port in $Ports) {

    # capture loop vars explicitly (Windows PS hates closure of loop variables)
    $currentPort  = $port
    $currentTarget = $Target
    $currentTimeout = $Timeout
    $currentSem = $sem

    # throttle
    $null = $currentSem.WaitAsync()

    $task = [System.Threading.Tasks.Task]::Run({
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $async = $client.BeginConnect($currentTarget, $currentPort, $null, $null)
            $success = $async.AsyncWaitHandle.WaitOne($currentTimeout)

            if ($success -and $client.Connected) {
                $client.EndConnect($async)
                return [PSCustomObject]@{
                    Port  = $currentPort
                    State = "Open"
                }
            }
        } catch { }
        finally {
            try { $client.Close() } catch { }
            $currentSem.Release() | Out-Null
        }
    })

    $jobs.Add($task)
}

# Wait for everything to finish
[System.Threading.Tasks.Task]::WaitAll($jobs.ToArray())

# Collect results
$openPorts = $jobs |
    Where-Object { $_.Result -ne $null } |
    ForEach-Object { $_.Result } |
    Sort-Object Port

Write-Host ""
Write-Host ("Open ports on {0}:" -f $Target)
$openPorts | Format-Table -AutoSize
