param(
    [string]$ip,
    [int]$port
)

# Create a TCP client
$client = New-Object System.Net.Sockets.TcpClient

try {
    # Connect to the target
    $client.Connect($ip, $port)

    # Get the network stream
    $stream = $client.GetStream()

    # Create an SSL stream
    $sslStream = New-Object System.Net.Security.SslStream($stream, $false,
        { $true }) # Simple server certificate validation callback

    # Authenticate the client; use the server's hostname for validation
    $sslStream.AuthenticateAsClient($ip)

    # Create a buffer to store the response
    $buffer = New-Object Byte[] 1024

    # Read data from the SSL stream
    $bytesRead = $sslStream.Read($buffer, 0, $buffer.Length)

    # Convert the bytes to a string
    $banner = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)

    Write-Output "Banner: $banner"
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
}
finally {
    $client.Close()
}
