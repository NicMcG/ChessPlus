# Waits until no balancing games of the given round are still running.
# (tasklist cuts long program names short, so this checks each process's command line.)
param([string]$Round)
while ($true) {
	$running = Get-CimInstance Win32_Process -Filter "Name like 'Godot%'" | Where-Object { $_.CommandLine -match "results/$Round/" }
	if (-not $running) { break }
	Start-Sleep -Seconds 30
}
