#!/usr/bin/env python3
"""Package only the installable addon, using stable ZIP metadata and a checksum.

Run from any directory with Python 3. No downloads or third-party packages.
Catalog tooling, tests, graphics and publishing documents stay in the repository.
"""
import hashlib
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "MusicSCAN"
FILES = (
    "MusicSCAN.toc", "Database.lua", "MusicSCAN.lua", "UI.lua",
    "README.md", "CHANGELOG.md", "LICENSE.txt", "SOURCES.md",
)


def main():
    toc = (ADDON / "MusicSCAN.toc").read_text(encoding="utf-8")
    core = (ADDON / "MusicSCAN.lua").read_text(encoding="utf-8")
    version = re.search(r"^## Version: (.+)$", toc, re.M).group(1).strip()
    core_version = re.search(r'ns.VERSION = "([^"]+)"', core).group(1)
    if version != core_version:
        raise SystemExit("TOC and core versions disagree.")
    loaded = [line.strip() for line in toc.splitlines()
              if line.strip() and not line.startswith("##")]
    if loaded != ["Database.lua", "MusicSCAN.lua", "UI.lua"]:
        raise SystemExit("Unexpected TOC load order; review before packaging.")
    actual = {path.name for path in ADDON.iterdir()}
    if actual != set(FILES):
        raise SystemExit(f"Unexpected addon contents: {actual ^ set(FILES)}")
    for name in FILES:
        if not (ADDON / name).is_file() or (ADDON / name).is_symlink():
            raise SystemExit(f"Expected a regular release file: {name}")

    # The version is used only as a safe local filename, never as shell input.
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", version)
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    archive = output / f"MusicSCAN-{slug}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=9) as target:
        for name in sorted(FILES):
            info = zipfile.ZipInfo(f"MusicSCAN/{name}", date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            target.writestr(info, (ADDON / name).read_bytes(), compresslevel=9)
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None:
            raise SystemExit("ZIP integrity check failed.")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (output / "SHA256SUMS.txt").write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    print(f"Built {archive.name}: {archive.stat().st_size:,} bytes; {len(FILES)} files")
    print(f"SHA256 {digest}")


if __name__ == "__main__":
    main()
