# Create a log file to confirm the script ran on boot
$logFilePath = "C:\\startup_log.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"Startup script ran at $timestamp" | Out-File -FilePath $logFilePath -Append
