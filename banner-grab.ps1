# Define the target IP address and port
$ipAddress = "target_ip_address"
$port = target_port_number

# Create a TCP client
$client = New-Object System.Net.Sockets.TcpClient

try {
    # Connect to the target
    $client.Connect($ipAddress, $port)

    # Get the network stream
    $stream = $client.GetStream()

    # Create a buffer to store the response
    $buffer = New-Object Byte[] 1024

    # Read data from the stream
    $bytesRead = $stream.Read($buffer, 0, $buffer.Length)

    # Convert the bytes to a string
    $banner = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)

    # Output the banner
    Write-Output "Banner: $banner"
}
catch {
    Write-Output "Error: $_"
}
finally {
    # Close the connection
    $client.Close()
}
