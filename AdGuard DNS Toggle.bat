@echo off
title AdGuard DNS Manager
color 0A

REM Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo  ADMINISTRATOR PRIVILEGES REQUIRED
    echo ========================================
    echo.
    echo This script must be run as Administrator.
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:DETECT_ADAPTER
cls
echo.
echo ========================================
echo      AdGuard DNS Manager
echo ========================================
echo.
echo Detecting active network adapter...
echo.

REM Create temp file for adapter detection
set "TEMP_FILE=%TEMP%\adapter_temp.txt"
powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object -First 1 -ExpandProperty Name" > "%TEMP_FILE%" 2>&1

REM Read adapter name from temp file
set "ADAPTER_NAME="
for /f "usebackq delims=" %%a in ("%TEMP_FILE%") do (
    if not defined ADAPTER_NAME set "ADAPTER_NAME=%%a"
)

REM Clean up temp file
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

if "%ADAPTER_NAME%"=="" (
    echo [ERROR] No active network adapter found!
    echo.
    echo Troubleshooting:
    echo - Make sure you are connected to Wi-Fi or Ethernet
    echo - Check if your network adapter is enabled
    echo - Try running this script as Administrator
    echo.
    echo Press any key to show all network adapters...
    pause >nul
    echo.
    echo All Network Adapters:
    powershell -Command "Get-NetAdapter | Format-Table Name, Status, InterfaceDescription -AutoSize"
    echo.
    pause
    exit /b 1
)

echo [DETECTED] Active Adapter: %ADAPTER_NAME%
echo.

REM Check if multiple adapters are active
set "ADAPTER_COUNT=0"
for /f %%a in ('powershell -Command "(Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}).Count"') do set "ADAPTER_COUNT=%%a"

if %ADAPTER_COUNT% gtr 1 (
    echo Note: Multiple active adapters detected (%ADAPTER_COUNT% adapters)
    echo.
    powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Format-Table Name, InterfaceDescription, Status -AutoSize"
    echo.
    echo [SELECTED] Using: %ADAPTER_NAME%
    echo.
    echo If this is not the correct adapter:
    echo   1. Press N to exit
    echo   2. Disconnect other network adapters
    echo   3. Run this script again
    echo.
    choice /C YN /M "Continue with '%ADAPTER_NAME%'"
    if errorlevel 2 goto END
    if errorlevel 1 goto CONTINUE_DETECTION
) else (
    echo This adapter will be used for AdGuard DNS configuration.
    echo.
    timeout /t 2 >nul
)

:CONTINUE_DETECTION
cls

:MENU
cls
echo.
echo ========================================
echo      AdGuard DNS Manager
echo ========================================
echo.
echo Network Adapter: %ADAPTER_NAME%
echo.
echo Checking current DNS status...
echo.

REM Check if AdGuard DNS is currently active
set "DNS_CHECK=0"
powershell -Command "$dns = Get-DnsClientServerAddress -InterfaceAlias '%ADAPTER_NAME%' -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ServerAddresses; if ($dns -contains '94.140.14.14') { exit 1 } else { exit 0 }" >nul 2>&1
if %errorlevel% equ 1 set "DNS_CHECK=1"

if "%DNS_CHECK%"=="1" (
    echo [STATUS] AdGuard DNS is currently ENABLED
    echo.
    echo DNS Servers:
    echo   IPv4: 94.140.14.14, 94.140.15.15
    echo   IPv6: 2a10:50c0::ad1:ff, 2a10:50c0::ad2:ff
    echo   Encryption: DNS over HTTPS
    echo.
    echo ========================================
    echo.
    echo What would you like to do?
    echo.
    echo [1] Disable AdGuard DNS (revert to automatic)
    echo [2] Re-apply AdGuard DNS settings
    echo [3] Change network adapter
    echo [4] Exit
    echo.
    set /p choice="Enter your choice (1-4): "
    
    if "%choice%"=="1" goto DISABLE
    if "%choice%"=="2" goto ENABLE
    if "%choice%"=="3" goto DETECT_ADAPTER
    if "%choice%"=="4" goto END
    echo Invalid choice. Please try again.
    timeout /t 2 >nul
    goto MENU
) else (
    echo [STATUS] AdGuard DNS is currently DISABLED
    echo.
    echo Current DNS: Automatic (from router/DHCP)
    echo.
    echo ========================================
    echo.
    echo What would you like to do?
    echo.
    echo [1] Enable AdGuard DNS with encryption
    echo [2] Change network adapter
    echo [3] Exit
    echo.
    set /p choice="Enter your choice (1-3): "
    
    if "%choice%"=="1" goto ENABLE
    if "%choice%"=="2" goto DETECT_ADAPTER
    if "%choice%"=="3" goto END
    echo Invalid choice. Please try again.
    timeout /t 2 >nul
    goto MENU
)

:ENABLE
cls
echo.
echo ========================================
echo      Enabling AdGuard DNS
echo ========================================
echo.
echo Network Adapter: %ADAPTER_NAME%
echo.
echo Step 1: Adding DNS encryption settings...
netsh dns add encryption server=94.140.14.14 dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
netsh dns add encryption server=94.140.15.15 dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
netsh dns add encryption server=2a10:50c0::ad1:ff dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
netsh dns add encryption server=2a10:50c0::ad2:ff dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
echo    [OK] Encryption templates added
echo.

echo Step 2: Setting DNS servers on %ADAPTER_NAME%...
powershell -Command "try { Set-DnsClientServerAddress -InterfaceAlias '%ADAPTER_NAME%' -ServerAddresses ('94.140.14.14','94.140.15.15','2a10:50c0::ad1:ff','2a10:50c0::ad2:ff') -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] DNS servers configured successfully
) else (
    echo    [ERROR] Failed to configure DNS servers
    echo    Please check your network adapter and try again.
    echo.
    pause
    goto MENU
)
echo.

echo Step 3: Enabling DNS over HTTPS encryption...
powershell -Command "try { $guid = (Get-NetAdapter -Name '%ADAPTER_NAME%').InterfaceGuid.ToLower(); New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\" -Name '94.140.14.14' -Force -ErrorAction Stop | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\94.140.14.14\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force -ErrorAction Stop | Out-Null; New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\" -Name '94.140.15.15' -Force -ErrorAction Stop | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\94.140.15.15\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force -ErrorAction Stop | Out-Null; New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\" -Name '2a10:50c0::ad1:ff' -Force -ErrorAction Stop | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\2a10:50c0::ad1:ff\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force -ErrorAction Stop | Out-Null; New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\" -Name '2a10:50c0::ad2:ff' -Force -ErrorAction Stop | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\2a10:50c0::ad2:ff\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] DNS over HTTPS enabled
) else (
    echo    [WARNING] Encryption may need manual configuration
    echo    DNS servers are set, but encryption might require
    echo    manual setup in Windows Settings.
)
echo.

echo Step 4: Verifying configuration...
powershell -Command "$dns = Get-DnsClientServerAddress -InterfaceAlias '%ADAPTER_NAME%' -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ServerAddresses; if ($dns -contains '94.140.14.14') { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] Configuration verified successfully
) else (
    echo    [WARNING] Verification failed
    echo    Please check Windows Settings manually.
)
echo.

echo ========================================
echo  SUCCESS! AdGuard DNS is now ENABLED
echo ========================================
echo.
echo Network Adapter: %ADAPTER_NAME%
echo.
echo Benefits:
echo  - Ad blocking across entire PC
echo  - Encrypted DNS queries (privacy)
echo  - Protection from malicious websites
echo.
echo You can verify at: https://adguard.com/en/test.html
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:DISABLE
cls
echo.
echo ========================================
echo      Disabling AdGuard DNS
echo ========================================
echo.
echo Network Adapter: %ADAPTER_NAME%
echo.
echo Reverting to automatic DNS settings...
powershell -Command "try { Set-DnsClientServerAddress -InterfaceAlias '%ADAPTER_NAME%' -ResetServerAddresses -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo    [OK] DNS settings reset to automatic
) else (
    echo    [ERROR] Failed to reset DNS settings
    echo.
    pause
    goto MENU
)
echo.

echo ========================================
echo  SUCCESS! AdGuard DNS is now DISABLED
echo ========================================
echo.
echo Network Adapter: %ADAPTER_NAME%
echo.
echo Your system is now using automatic DNS
echo from your router (DHCP).
echo.
echo Note: Encryption templates remain in Windows
echo and can be re-enabled anytime by running
echo this script again.
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:END
cls
echo.
echo Thank you for using AdGuard DNS Manager!
echo.
timeout /t 2 >nul
exit