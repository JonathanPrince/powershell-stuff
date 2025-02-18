param(
    [string]$hostname,
    [int]$port
)

# Create a TCP client
$client = New-Object System.Net.Sockets.TcpClient

try {
    Write-Output "Connecting to $hostname on port $port..."
    # Connect to the target
    $client.Connect($hostname, $port)

    Write-Output "Connection established."

    # Get the network stream
    $stream = $client.GetStream()

    # Create an SSL stream
    $sslStream = New-Object System.Net.Security.SslStream($stream, $false,
        { $true }) # Simple server certificate validation callback

    Write-Output "Initiating TLS handshake..."

    # Authenticate the client; use the server's hostname for validation
    $sslStream.AuthenticateAsClient($hostname)

    Write-Output "TLS handshake completed."

    # Output SSL/TLS session details
    Write-Output "SSL/TLS Protocol: $($sslStream.SslProtocol)"
    Write-Output "Cipher Algorithm: $($sslStream.CipherAlgorithm)"
    Write-Output "Cipher Strength: $($sslStream.CipherStrength)"
    Write-Output "Hash Algorithm: $($sslStream.HashAlgorithm)"
    Write-Output "Hash Strength: $($sslStream.HashStrength)"
    Write-Output "Key Exchange Algorithm: $($sslStream.KeyExchangeAlgorithm)"
    Write-Output "Key Exchange Strength: $($sslStream.KeyExchangeStrength)"

    # Optionally, send a request to the server
    # $request = "GET / HTTP/1.1`r`nHost: $hostname`r`nConnection: close`r`n`r`n"
    # $requestBytes = [System.Text.Encoding]::ASCII.GetBytes($request)
    # $sslStream.Write($requestBytes, 0, $requestBytes.Length)

    # Create a buffer to store the response
    $buffer = New-Object Byte[] 4096

    # Read data from the SSL stream
    $bytesRead = $sslStream.Read($buffer, 0, $buffer.Length)

    # Convert the bytes to a string
    $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)

    Write-Output "Received response:"
    Write-Output $response
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
}
finally {
    $client.Close()
    Write-Output "Connection closed."
}
