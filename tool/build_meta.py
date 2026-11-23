#!/usr/bin/env python3
"""Sumber tunggal identitas build Celenium Wallet.

Semua nilai (nama, publisher, versi, ID) diambil dari tool/build_meta.json dan
pubspec.yaml, lalu distempel ke berkas build tiap platform:

    python3 tool/build_meta.py stamp   # tulis identitas ke Runner.rc, installer.iss, AppStream, .desktop
    python3 tool/build_meta.py check   # gagal (exit 1) kalau ada yang tidak konsisten
    python3 tool/build_meta.py show    # cetak identitas hasil resolve

Jalankan stamp sebelum build, check sesudahnya.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META_PATH = ROOT / "tool" / "build_meta.json"
PUBSPEC = ROOT / "pubspec.yaml"

RUNNER_RC = ROOT / "windows" / "runner" / "Runner.rc"
INSTALLER_ISS = ROOT / "windows" / "installer.iss"
MAIN_CPP = ROOT / "windows" / "runner" / "main.cpp"
APPDATA = ROOT / "linux" / "packaging" / "CeleniumWallet.appdata.xml"
DESKTOP = ROOT / "linux" / "packaging" / "CeleniumWallet.desktop"


def read_version() -> tuple[str, int]:
    text = PUBSPEC.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*(\S+)", text, re.MULTILINE)
    if not match:
        sys.exit("pubspec.yaml tidak punya baris version:")
    raw = match.group(1)
    name, _, build = raw.partition("+")
    return name.strip(), int(build) if build.isdigit() else 0


def load() -> dict:
    meta = json.loads(META_PATH.read_text(encoding="utf-8"))
    meta["version"], meta["build"] = read_version()
    meta["version_4"] = f'{meta["version"]}.{meta["build"]}'
    return meta


def sub_once(text: str, pattern: str, repl: str, label: str) -> str:
    # repl dipakai apa adanya (lambda) supaya backslash di string RC tidak ditafsirkan
    new, count = re.subn(pattern, lambda _match: repl, text, count=1)
    if count != 1:
        sys.exit(f"stamp gagal: pola '{label}' tidak ditemukan di {pattern[:40]}…")
    return new


def stamp_runner_rc(m: dict) -> None:
    text = RUNNER_RC.read_text(encoding="utf-8")
    block = (
        r'#if defined\(FLUTTER_VERSION\)\n#define VERSION_AS_STRING FLUTTER_VERSION\n'
        r'#else\n#define VERSION_AS_STRING "[^"]*"\n#endif'
    )
    line = r'#define VERSION_AS_STRING "[^"]*"'
    comment = "// Ditetapkan tool/build_meta.py: versi tampil tanpa build number.\n"
    if re.search(block, text):
        text = sub_once(text, block, comment + f'#define VERSION_AS_STRING "{m["version"]}"', "VERSION_AS_STRING")
    else:
        # sudah pernah distempel: cukup perbarui barisnya (idempoten)
        text = sub_once(text, line, f'#define VERSION_AS_STRING "{m["version"]}"', "VERSION_AS_STRING")
    for key, value in (
        ("CompanyName", m["publisher"]),
        ("FileDescription", m["name"]),
        ("ProductName", m["name"]),
        ("LegalCopyright", m["copyright"]),
        ("InternalName", m["exe"]),
    ):
        text = sub_once(
            text,
            r'VALUE "' + key + r'", "[^"]*" "\\0"',
            f'VALUE "{key}", "{value}" "\\0"',
            key,
        )
    RUNNER_RC.write_text(text, encoding="utf-8")


def stamp_installer(m: dict) -> None:
    text = INSTALLER_ISS.read_text(encoding="utf-8")
    defines = {
        "MyAppName": m["name"],
        "MyAppVersion": m["version"],
        "MyAppPublisher": m["publisher"],
        "MyAppURL": m["url"],
        "MyAppExeName": f'{m["exe"]}.exe',
        "MyAppUserModelID": m["aumid"],
    }
    for key, value in defines.items():
        text = sub_once(
            text,
            r'#define ' + key + r' "[^"]*"',
            f'#define {key} "{value}"',
            key,
        )
    if "VersionInfoVersion=" in text:
        text = sub_once(
            text,
            r"VersionInfoVersion=[^\r\n]*",
            f'VersionInfoVersion={m["version_4"]}',
            "VersionInfoVersion",
        )
    if "VersionInfoCopyright=" in text:
        text = sub_once(
            text,
            r"VersionInfoCopyright=[^\r\n]*",
            f'VersionInfoCopyright={m["copyright"]}',
            "VersionInfoCopyright",
        )
    INSTALLER_ISS.write_text(text, encoding="utf-8")


def stamp_appstream(m: dict) -> None:
    if not APPDATA.exists():
        return
    text = APPDATA.read_text(encoding="utf-8")
    text = sub_once(text, r"<id>[^<]*</id>", f'<id>{m["app_id"]}</id>', "appstream id")
    text = sub_once(text, r"<name>[^<]*</name>", f'<name>{m["name"]}</name>', "appstream name")
    text = sub_once(
        text,
        r'<developer id="[^"]*">\s*<name>[^<]*</name>',
        f'<developer id="web.celenium">\n    <name>{m["publisher"]}</name>',
        "appstream developer",
    )
    text = sub_once(
        text,
        r'<release version="[^"]*"',
        f'<release version="{m["version"]}"',
        "appstream release",
    )
    text = sub_once(text, r"<summary>[^<]*</summary>", f'<summary>{m["summary"]}</summary>', "appstream summary")
    APPDATA.write_text(text, encoding="utf-8")


def stamp_desktop(m: dict) -> None:
    if not DESKTOP.exists():
        return
    text = DESKTOP.read_text(encoding="utf-8")
    fields = {
        "Name": m["name"],
        "Comment": m["summary"],
        "Exec": f'{m["exe"]} %U',
        "Icon": m["name"].replace(" ", ""),
        "StartupWMClass": m["app_id"],
        "X-AppImage-Version": m["version"],
        "Categories": m["categories"],
        "X-AppImage-Name": m["name"],
    }
    lines = text.splitlines()
    for key, value in fields.items():
        pattern = re.compile(rf"^{re.escape(key)}=.*$")
        for i, line in enumerate(lines):
            if pattern.match(line):
                lines[i] = f"{key}={value}"
                break
        else:
            lines.append(f"{key}={value}")
    DESKTOP.write_text("\n".join(lines) + "\n", encoding="utf-8")


def cmd_stamp() -> int:
    m = load()
    stamp_runner_rc(m)
    stamp_installer(m)
    stamp_appstream(m)
    stamp_desktop(m)
    print(f'stamp OK — {m["name"]} {m["version"]} (+{m["build"]}) oleh {m["publisher"]}')
    return 0


def cmd_check(argv: list[str]) -> int:
    m = load()
    checks: list[tuple[str, bool, str]] = []

    rc = RUNNER_RC.read_text(encoding="utf-8")
    checks.append(("Runner.rc CompanyName", f'VALUE "CompanyName", "{m["publisher"]}"' in rc, m["publisher"]))
    checks.append(("Runner.rc LegalCopyright", f'VALUE "LegalCopyright", "{m["copyright"]}"' in rc, m["copyright"]))
    checks.append(
        (
            "Runner.rc FileVersion string",
            f'#define VERSION_AS_STRING "{m["version"]}"' in rc,
            m["version"],
        )
    )

    iss = INSTALLER_ISS.read_text(encoding="utf-8")
    for key, value in (
        ("MyAppName", m["name"]),
        ("MyAppVersion", m["version"]),
        ("MyAppPublisher", m["publisher"]),
        ("MyAppUserModelID", m["aumid"]),
    ):
        checks.append((f"installer.iss {key}", f'#define {key} "{value}"' in iss, value))

    main_cpp = MAIN_CPP.read_text(encoding="utf-8")
    checks.append(("main.cpp AppUserModelID", f'"{m["aumid"]}"' in main_cpp, m["aumid"]))

    if APPDATA.exists():
        app = APPDATA.read_text(encoding="utf-8")
        checks.append(("AppStream id", f'<id>{m["app_id"]}</id>' in app, m["app_id"]))
        checks.append(("AppStream developer", f'<name>{m["publisher"]}</name>' in app, m["publisher"]))
        checks.append(("AppStream release", f'<release version="{m["version"]}"' in app, m["version"]))

    if DESKTOP.exists():
        desk = DESKTOP.read_text(encoding="utf-8")
        checks.append(("desktop StartupWMClass", f'StartupWMClass={m["app_id"]}' in desk, m["app_id"]))
        checks.append(("desktop X-AppImage-Version", f'X-AppImage-Version={m["version"]}' in desk, m["version"]))

    failed = 0
    for label, ok, value in checks:
        print(f'{"PASS" if ok else "FAIL"}  {label:<32} {value}')
        failed += 0 if ok else 1
    print(f'\n{len(checks) - failed}/{len(checks)} cek lolos')
    return 1 if failed else 0


def cmd_show() -> int:
    m = load()
    for key in ("name", "publisher", "version", "build", "version_4", "app_id", "aumid", "exe", "url"):
        print(f"{key:<12} {m[key]}")
    return 0


def main() -> int:
    args = sys.argv[1:]
    command = args[0] if args else "show"
    if command == "stamp":
        return cmd_stamp()
    if command == "check":
        return cmd_check(args[1:])
    if command == "show":
        return cmd_show()
    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
