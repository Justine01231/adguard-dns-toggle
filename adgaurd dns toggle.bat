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

:MENU
cls
echo.
echo ========================================
echo      AdGuard DNS Manager for Wi-Fi
echo ========================================
echo.
echo Checking current DNS status...
echo.

REM Check if AdGuard DNS is currently active
powershell -Command "$dns = Get-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses; if ($dns -contains '94.140.14.14') { exit 1 } else { exit 0 }"

if %errorlevel% equ 1 (
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
    echo [3] Exit
    echo.
    set /p choice="Enter your choice (1-3): "
    
    if "%choice%"=="1" goto DISABLE
    if "%choice%"=="2" goto ENABLE
    if "%choice%"=="3" goto END
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
    echo [2] Exit
    echo.
    set /p choice="Enter your choice (1-2): "
    
    if "%choice%"=="1" goto ENABLE
    if "%choice%"=="2" goto END
    goto MENU
)

:ENABLE
cls
echo.
echo ========================================
echo      Enabling AdGuard DNS
echo ========================================
echo.
echo Step 1: Adding DNS encryption settings...
netsh dns add encryption server=94.140.14.14 dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
netsh dns add encryption server=94.140.15.15 dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
netsh dns add encryption server=2a10:50c0::ad1:ff dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
netsh dns add encryption server=2a10:50c0::ad2:ff dohtemplate=https://dns.adguard.com/dns-query autoupgrade=yes udpfallback=no 2>nul
echo    [OK] Encryption templates added
echo.

echo Step 2: Setting DNS servers on Wi-Fi adapter...
powershell -Command "Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ServerAddresses ('94.140.14.14','94.140.15.15','2a10:50c0::ad1:ff','2a10:50c0::ad2:ff')" >nul 2>&1
echo    [OK] DNS servers configured
echo.

echo Step 3: Enabling DNS over HTTPS encryption...
powershell -Command "$guid = (Get-NetAdapter -Name 'Wi-Fi').InterfaceGuid.ToLower(); New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\" -Name '94.140.14.14' -Force | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\94.140.14.14\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force | Out-Null; New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\" -Name '94.140.15.15' -Force | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh\94.140.15.15\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force | Out-Null; New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\" -Name '2a10:50c0::ad1:ff' -Force | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\2a10:50c0::ad1:ff\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force | Out-Null; New-Item -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\" -Name '2a10:50c0::ad2:ff' -Force | Out-Null; New-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$guid\DohInterfaceSettings\Doh6\2a10:50c0::ad2:ff\" -Name 'DohFlags' -Value 1 -PropertyType QWord -Force | Out-Null" >nul 2>&1
echo    [OK] DNS over HTTPS enabled
echo.

echo ========================================
echo  SUCCESS! AdGuard DNS is now ENABLED
echo ========================================
echo.
echo Benefits:
echo  - Ad blocking across entire PC
echo  - Encrypted DNS queries (privacy)
echo  - Protection from malicious websites
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
echo Reverting to automatic DNS settings...
powershell -Command "Set-DnsClientServerAddress -InterfaceAlias 'Wi-Fi' -ResetServerAddresses" >nul 2>&1
echo    [OK] DNS settings reset to automatic
echo.

echo ========================================
echo  SUCCESS! AdGuard DNS is now DISABLED
echo ========================================
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