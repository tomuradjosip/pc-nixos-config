# FINA Digital Signature Setup

This document describes how to use FINA digital signature tools on NixOS for Croatian e-services (e-Građani, e-Poslovanje, etc.).

## Quick Start

After running `nixos-rebuild switch`, the following is **automatically configured**:
- `signergy-fina` - Digital signing application
- `SACTools` / `SACMonitor` - Token management tools
- `pcscd` service - Smart card daemon (starts automatically)
- `pcsc_scan`, `modutil`, `certutil` - Diagnostic tools

**One-time browser setup required** (see [Browser Configuration](#browser-configuration) below).

## Installed Packages

### SignErgy Fina
Digital document signing application from FINA.

**Launch:** `signergy-fina` or find "SignErgy Fina" in your application menu.

**Use for:**
- Signing PDF documents
- Signing electronic forms
- Digital authentication

### SafeNet Authentication Client
Smart card and eToken management tools.

| Command | Description |
|---------|-------------|
| `SACTools` | Token management GUI (view certificates, change PIN, etc.) |
| `SACMonitor` | System tray monitor showing token status |

## Browser Configuration

To use your smart card/eToken for web authentication (e-Građani, FINA services, etc.), you need to load the PKCS#11 security module in your browser.

**Important:** There are two PKCS#11 libraries available:
- `/run/current-system/sw/lib/opensc-pkcs11.so` - **OpenSC** (works with Gemalto IDPrime tokens)
- `/run/current-system/sw/lib/libeToken.so` - **SafeNet** (works with SafeNet eTokens)

Use `pkcs11-tool` to determine which library works with your token:
```bash
pkcs11-tool --module /run/current-system/sw/lib/opensc-pkcs11.so -L
```

### Firefox

1. Open Firefox
2. Go to **Settings** → **Privacy & Security**
3. Scroll down to **Security** section
4. Click **Security Devices...**
5. Click **Load**
6. Enter:
   - **Module Name:** `Gemalto IDPrime` (or any name you prefer)
   - **Module filename:** `/run/current-system/sw/lib/opensc-pkcs11.so`
7. Click **OK**

Your smart card certificates should now appear when accessing sites that require authentication.

### Brave

Brave uses the same configuration as Chrome (see below).

### Google Chrome / Chromium

Chrome and Brave don't have a built-in PKCS#11 module manager. You need to use the `modutil` command-line tool or configure via policy.

Run these commands once to register the PKCS#11 module:

```bash
# Create NSS database if it doesn't exist
mkdir -p ~/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -N --empty-password

# Add the PKCS#11 module (use opensc-pkcs11.so for Gemalto IDPrime)
modutil -dbdir sql:$HOME/.pki/nssdb -add "Gemalto IDPrime" -libfile /run/current-system/sw/lib/opensc-pkcs11.so
```

To verify it's loaded:
```bash
modutil -dbdir sql:$HOME/.pki/nssdb -list
```

To remove it later (if needed):
```bash
modutil -dbdir sql:$HOME/.pki/nssdb -delete "Gemalto IDPrime"
```

## Troubleshooting

### Token not detected

1. **Check if pcscd is running:**
   ```bash
   systemctl status pcscd
   ```

2. **Restart pcscd:**
   ```bash
   sudo systemctl restart pcscd
   ```

3. **Check if token is recognized:**
   ```bash
   # List connected readers
   pcsc_scan
   ```
   Press `Ctrl+C` to exit.

4. **If you get "Access denied":**
   
   This means your user doesn't have permission to access pcscd. Verify polkit rules are configured in `modules/packages.nix` and that you're in the `wheel` group:
   ```bash
   groups  # should include 'wheel'
   ```
   After adding polkit rules, rebuild and log out/in for changes to take effect.

### "No certificates found" in browser

1. Make sure your token/smart card is inserted
2. Open `SACTools` and verify you can see your certificates
3. Re-check the PKCS#11 module path in browser settings

### PIN entry dialog doesn't appear

Some applications may need the `pinentry` program. It should be available, but if not:
```bash
# Test PIN entry
SACTools
```
Enter your PIN when prompted to verify the token works.

### SignErgy Fina won't start

1. Make sure you have a display (X11/Wayland) running
2. Check for errors:
   ```bash
   signergy-fina 2>&1 | head -20
   ```

## File Locations

| Item | Path |
|------|------|
| OpenSC PKCS#11 Library | `/run/current-system/sw/lib/opensc-pkcs11.so` |
| SafeNet PKCS#11 Library | `/run/current-system/sw/lib/libeToken.so` |
| SafeNet config | `/run/current-system/sw/etc/eToken.conf` |
| SignErgy home | `/run/current-system/sw/share/signergy-fina/` |

## Technical Details

These packages are built from FINA's official Linux distribution:
- **Source:** https://rdc.fina.hr/download/Linux.zip
- **SignErgy Fina version:** 3.21.003
- **SafeNet Authentication Client version:** 10.9.4723

The packages are defined in:
- `packages/signergy-fina.nix`
- `packages/safenet-authentication-client.nix`

They use `autoPatchelfHook` to automatically patch ELF binaries for NixOS compatibility.
