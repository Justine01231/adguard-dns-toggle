# AdGuard DNS Toggle for Windows 11

A smart batch script that enables or disables AdGuard DNS over HTTPS on Windows 11 with automatic detection and easy toggling.

## Features

✅ **Auto-Detection** - Automatically detects current DNS status  
✅ **Smart Menu** - Shows relevant options based on current state  
✅ **DNS over HTTPS** - Encrypts DNS queries for privacy  
✅ **Ad Blocking** - Blocks ads and trackers system-wide  
✅ **Easy Toggle** - One-click enable/disable  

## What This Does

When enabled, this script:
- 🔒 Encrypts your DNS queries using DNS over HTTPS (DoH)
- 🛡️ Blocks ads, trackers, and malicious websites across your entire PC
- 🚀 Prevents your ISP from seeing which websites you visit
- ✨ Uses AdGuard's fast and secure DNS servers

## Requirements

- Windows 11 (or Windows 10 with DoH support)
- Administrator privileges
- Wi-Fi or Ethernet connection

## Installation

1. Download `AdGuard DNS Toggle.bat`
2. Save it anywhere on your computer
3. Right-click the file and select **"Run as administrator"**

## Usage

Simply run the batch file as administrator. The script will:

1. **Detect** if AdGuard DNS is currently enabled or disabled
2. **Display** a menu with appropriate options
3. **Apply** your selection automatically

### Menu Options

**When Disabled:**
- Enable AdGuard DNS with encryption
- Exit

**When Enabled:**
- Disable AdGuard DNS (revert to automatic)
- Re-apply AdGuard DNS settings
- Exit

## DNS Servers Used

**IPv4:**
- Primary: `94.140.14.14`
- Secondary: `94.140.15.15`

**IPv6:**
- Primary: `2a10:50c0::ad1:ff`
- Secondary: `2a10:50c0::ad2:ff`

**Encryption:** `https://dns.adguard.com/dns-query`

## How It Works

The script performs the following actions:

### Enabling AdGuard DNS:
1. Adds DNS encryption templates to Windows
2. Sets AdGuard DNS servers on your network adapter
3. Configures registry settings for DNS over HTTPS
4. Enables "encrypted only" mode

### Disabling AdGuard DNS:
1. Resets DNS settings to automatic (DHCP)
2. Reverts to your router's default DNS servers
3. Keeps encryption templates for easy re-enabling

## Testing

After enabling, you can verify it's working:

1. Visit **https://adguard.com/en/test.html**
2. Should confirm you're using AdGuard DNS
3. Browse ad-heavy websites - you should see fewer ads

## Troubleshooting

**"Administrator privileges required" error:**
- Right-click the file and select "Run as administrator"

**Script doesn't detect current status:**
- Make sure your Wi-Fi adapter is named "Wi-Fi"
- Check your adapter name: Run `Get-NetAdapter` in PowerShell

**DNS not working after enabling:**
- Try disabling and re-enabling
- Check your network connection
- Restart your computer

## Customization

If your network adapter has a different name (e.g., "Ethernet" or "Wi-Fi 2"):

1. Open the `.bat` file in a text editor
2. Find all instances of `'Wi-Fi'`
3. Replace with your adapter name
4. Save and run

To find your adapter name, run in PowerShell:
```powershell
Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
```

## Credits

- **AdGuard DNS**: https://adguard-dns.io/
- Based on the setup guide: https://gist.github.com/krcm0209/2d8ceb00ebf5b6113d920b8120913c02

## License

MIT License - Feel free to use, modify, and distribute.

## Disclaimer

This script modifies your system's DNS settings. While it's safe to use, always ensure you understand what DNS settings do. You can always revert to automatic DNS settings using this same script.

## Contributing

Contributions, issues, and feature requests are welcome!

## Author

Created for easy AdGuard DNS management on Windows 11.

---

**⭐ If you find this useful, please star this repository!**