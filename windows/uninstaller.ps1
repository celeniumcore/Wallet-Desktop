# CEN Wallet - Windows Uninstaller
# Removes: app folder, shortcuts, registry entry
Write-Host "Menghapus CEN Wallet..." -ForegroundColor Yellow

# 1. Stop app
Get-Process -Name 'celenium_wallet' -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "  [1/4] Aplikasi ditutup" -ForegroundColor Green

# 2. Remove registry entry
$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\CENWallet"
if (Test-Path $regKey) {
    Remove-Item $regKey -Force
    Write-Host "  [2/4] Registrasi dihapus dari Control Panel" -ForegroundColor Green
} else {
    Write-Host "  [2/4] Registrasi sudah tidak ada" -ForegroundColor Yellow
}

# 3. Remove app folder
$folders = @(
    "$env:USERPROFILE\OneDrive\Desktop\CEN Wallet",
    "$env:USERPROFILE\Desktop\CEN Wallet"
)
foreach ($f in $folders) {
    if (Test-Path $f) {
        Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [3/4] Folder dihapus: $f" -ForegroundColor Green
    }
}

# 4. Remove shortcuts
$shortcuts = @(
    "$env:USERPROFILE\OneDrive\Desktop\CEN Wallet.lnk",
    "$env:USERPROFILE\Desktop\CEN Wallet.lnk",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\CEN Wallet.lnk"
)
foreach ($s in $shortcuts) {
    if (Test-Path $s) {
        Remove-Item $s -Force -ErrorAction SilentlyContinue
        Write-Host "  [4/4] Shortcut dihapus: $s" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "CEN Wallet berhasil dihapus dari komputer Anda." -ForegroundColor Green
Write-Host "Tekan Enter untuk menutup..."
Read-Host
