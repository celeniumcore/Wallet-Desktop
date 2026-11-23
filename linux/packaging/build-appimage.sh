#!/usr/bin/env bash
# Build AppImage sesuai standar: stamp identitas → build Flutter → rakit AppDir → appimagetool.
#
# Pakai:
#   ./linux/packaging/build-appimage.sh            # build penuh
#   SKIP_FLUTTER=1 ./linux/packaging/build-appimage.sh   # pakai hasil build sebelumnya
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FLUTTER="${FLUTTER:-$HOME/flutter-install/flutter/bin/flutter}"
APPIMAGETOOL="${APPIMAGETOOL:-/tmp/appimagetool.AppImage}"
DIST="$ROOT/dist"
APPDIR="$ROOT/build/appimage/CeleniumWallet.AppDir"
BUNDLE="$ROOT/build/linux/x64/release/bundle"

NAME=$(python3 tool/build_meta.py show | awk '$1=="name"{$1="";sub(/^ /,"");print}')
VERSION=$(python3 tool/build_meta.py show | awk '$1=="version"{print $2}')
ICON_MASTER=$(python3 -c "import json,sys;print(json.load(open('tool/build_meta.json'))['icon'])")

echo "[1/5] stamp identitas"
python3 tool/build_meta.py stamp
python3 tool/build_meta.py check

if [ "${SKIP_FLUTTER:-0}" != "1" ]; then
  echo "[2/5] flutter build linux --release"
  "$FLUTTER" build linux --release
else
  echo "[2/5] dilewati (SKIP_FLUTTER=1)"
fi

echo "[3/5] rakit AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/metainfo" "$APPDIR/usr/share/icons/hicolor"
cp -a "$BUNDLE/." "$APPDIR/usr/bin/"
cp linux/packaging/CeleniumWallet.desktop "$APPDIR/CeleniumWallet.desktop"
cp linux/packaging/CeleniumWallet.desktop "$APPDIR/usr/share/applications/"
cp linux/packaging/CeleniumWallet.appdata.xml "$APPDIR/usr/share/metainfo/"

# AppRun wajib: appimagetool tidak membuatnya sendiri, dan tanpa ini runtime
# berhenti dengan "execv error: No such file or directory".
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/sh
# Celenium Wallet — AppRun (dibuat saat build, lihat linux/packaging/build-appimage.sh)
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/celenium_wallet" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

echo "[4/5] render ikon"
python3 - "$ICON_MASTER" "$APPDIR" <<'PY'
import sys
from pathlib import Path
from PIL import Image

master, appdir = Path(sys.argv[1]), Path(sys.argv[2])
img = Image.open(master).convert("RGBA")
for size in (16, 24, 32, 48, 64, 128, 256, 512):
    target = appdir / "usr/share/icons/hicolor" / f"{size}x{size}" / "apps"
    target.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(target / "CeleniumWallet.png")
(root256 := appdir / "CeleniumWallet.png").write_bytes((appdir / "usr/share/icons/hicolor/256x256/apps/CeleniumWallet.png").read_bytes())
(appdir / ".DirIcon").write_bytes(root256.read_bytes())
PY

echo "[5/5] appimagetool"
mkdir -p "$DIST"
rm -f "$DIST/CeleniumWallet-x86_64.AppImage"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$DIST/CeleniumWallet-x86_64.AppImage"
sha256sum "$DIST/CeleniumWallet-x86_64.AppImage"
echo "selesai: $DIST/CeleniumWallet-x86_64.AppImage ($NAME $VERSION)"
