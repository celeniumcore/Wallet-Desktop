# Screenshot Celenium Wallet Desktop — 26 Nov 2026

Dihasilkan dari `lib/screenshot_harness.dart` (target Flutter Linux release) dengan data preview deterministik. Semua file PNG 2560×1640 kecuali `14_mobile_dompet` (390×844).

| File | Isi |
|---|---|
| `01_bahasa_id.png` | Onboarding — pilih bahasa Indonesia |
| `02_bahasa_en.png` | Onboarding — language selection (English) |
| `03_onboarding_wallet.png` | Onboarding — pembuatan/import dompet |
| `04_pin.png` | Layar PIN 6 digit |
| `05_dompet.png` | Dompet — dashboard default (koneksi live) |
| `06_kirim.png` | Kirim CEN — form revisi terbaru |
| `07_terima.png` | Terima — QR + alamat cen69 |
| `08_riwayat.png` | Riwayat — revisi terbaru (state kosong) |
| `09_setelan.png` | Setelan — menu utama |
| `10_scan_qr.png` | Scan QR — kamera/pemindai |
| `11_dompet_en.png` | Dompet — tampilan Bahasa Inggris |
| `12_import_frasa.png` | Import dompet — frasa pemulihan |
| `13_splash.png` | Splash screen — logo + tagline |
| `14_mobile_dompet.png` | Dompet — layout mobile 390×844 |
| `15_login_restore.png` | Login — restore dompet |
| `16_onboarding_back.png` | Onboarding — konfirmasi kembali |
| `20_menu_desktop.png` | Shell desktop — menu navigasi |
| `21_dompet_desktop.png` | Dompet — layout desktop lebar |
| `22_dompet_en.png` | Dompet desktop — Bahasa Inggris |
| `23_dompet_preview.png` | Dompet — preview data (grafik + 5 transaksi) |
| `26_dompet_add_address.png` | Dialog — tambah alamat tersimpan |
| `27_dompet_delete_address.png` | Dialog — konfirmasi hapus alamat |
| `28_setelan_seed.png` | Dialog — frasa pemulihan (BIP39 test vector) |
| `29_setelan_pin.png` | Dialog — atur PIN |
| `30_setelan_hapus_pin.png` | Dialog — hapus PIN |
| `31_setelan_logout.png` | Dialog — konfirmasi keluar |

Catatan: `28_setelan_seed` memakai BIP39 test vector, bukan frasa dompet nyata. `23_dompet_preview`, `26`–`31` memakai data contoh untuk keperluan dokumentasi UI.

Cara regenerasi:
```bash
cd ~/celenium-wallet-desktop
flutter build linux --release -t lib/screenshot_harness.dart
LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe xvfb-run -a --server-args="-screen 0 1440x900x24" ./build/linux/x64/release/bundle/celenium_wallet
```
