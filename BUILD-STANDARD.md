# Standar Build Celenium Wallet

Semua artefak build memakai satu sumber identitas. Jangan mengedit nilai-nilai ini
di `Runner.rc`, `installer.iss`, AppStream, atau `.desktop` secara manual — jalankan
stamp supaya keempat platform tetap sinkron.

## Sumber tunggal

| Berkas | Isi |
| --- | --- |
| `tool/build_meta.json` | nama app, **publisher**, copyright, URL, App ID, AUMID, nama exe, ikon |
| `pubspec.yaml` → `version:` | versi rilis (`1.0.3+4`) — dipakai semua platform |

Nilai tetap:

- **Publisher:** `Celenium Labs`
- **Nama produk:** `Celenium Wallet`
- **App ID (Linux / WM_CLASS):** `id.celenium.celenium_wallet`
- **AUMID (Windows):** `Celenium.Wallet`

`1.0.3+4` dibaca sebagai versi rilis `1.0.3` dan build number `4`. Windows
`FileVersion` string memakai `1.0.3` (tanpa `+4`) supaya rapi di Properties,
sedangkan angka `FILEVERSION` tetap `1,0,3,4`.

## Perintah

```bash
python3 tool/build_meta.py show    # tampilkan identitas hasil resolve
python3 tool/build_meta.py stamp   # tulis identitas ke semua berkas build (idempoten)
python3 tool/build_meta.py check   # 13 cek konsistensi; exit 1 kalau ada yang gagal
```

## Titik stamp

| Platform | Berkas | Field |
| --- | --- | --- |
| Windows exe | `windows/runner/Runner.rc` | `CompanyName`, `ProductName`, `FileDescription`, `LegalCopyright`, `VERSION_AS_STRING` |
| Windows installer | `windows/installer.iss` | `MyAppName`, `MyAppVersion`, `MyAppPublisher`, `MyAppUserModelID`, `VersionInfo*` |
| Linux | `linux/packaging/CeleniumWallet.appdata.xml` | `<developer><name>`, `<id>`, `<release version>` |
| Linux | `linux/packaging/CeleniumWallet.desktop` | `StartupWMClass`, `X-AppImage-Version`, `Icon`, `Exec` |
| Windows | `windows/runner/main.cpp` | AUMID untuk taskbar grouping |

## Alur build

Windows (jalankan di Windows, dari folder proyek):

```bat
build-installer.bat
```

Skrip itu menjalankan `build_meta.py stamp` dan `check` lebih dulu, lalu Inno Setup.
Kalau Python tidak ada di Windows, skrip memakai `wsl -e python3`; kalau keduanya
tidak ada, build berhenti dengan peringatan alih-alih menghasilkan installer tanpa
identitas.

Linux:

```bash
./linux/packaging/build-appimage.sh              # stamp + flutter build + AppImage
SKIP_FLUTTER=1 ./linux/packaging/build-appimage.sh   # pakai bundle terakhir
```

`AppRun` dibuat oleh skrip ini: appimagetool tidak membuatnya sendiri, dan tanpa
`AppRun` AppImage berhenti dengan `execv error: No such file or directory`.
