param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [int[]]$Ports = (1..1024),  # default range
    [int]$Timeout = 200,        # ms per port
    [int]$Concurrency = 100     # max parallel jobs
)

Write-Host ("Scanning {0} ..." -f $Target)

$jobs = @()

foreach ($port in $Ports) {

    # Throttle number of concurrent jobs
    while ((Get-Job -State Running).Count -ge $Concurrency) {
        Start-Sleep -Milliseconds 50
    }

    $jobs += Start-Job -ScriptBlock {
        param($Target, $Port, $Timeout)

        $client = New-Object System.Net.Sockets.TcpClient
        try {
            # Start async connect
            $iar = $client.BeginConnect($Target, $Port, $null, $null)
            $success = $iar.AsyncWaitHandle.WaitOne($Timeout)

            if ($success -and $client.Connected) {
                $client.EndConnect($iar)
                [PSCustomObject]@{
                    Port  = $Port
                    State = 'Open'
                }
            }
        } catch {
            # ignore errors (host unreachable, etc.)
        } finally {
            try { $client.Close() } catch {}
        }

    } -ArgumentList $Target, $port, $Timeout
}

if ($jobs.Count -gt 0) {
    # Wait for all jobs to finish
    $jobs | Wait-Job | Out-Null

    # Collect results
    $results = $jobs | Receive-Job
    Remove-Job $jobs

    $openPorts = $results |
        Where-Object { $_ -ne $null } |
        Sort-Object Port

    Write-Host ""
    Write-Host ("Open ports on {0}:" -f $Target)

    if ($openPorts) {
        $openPorts | Format-Table -AutoSize
    } else
        {
        Write-Host "No open ports found in the given range."
    }
} else {
    Write-Host "No ports to scan."
}
