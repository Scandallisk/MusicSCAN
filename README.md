# MusicSCAN — World of Warcraft Retail

**0.8.0 BETA1** · SCAN | Kilobytes Development

Less configuring. More listening.

5,493 music-file entries, split library/track panes, search, Favorites and themed views:
Cities, Forests, Taverns, PvP, Dungeons and Raids. Play captures the displayed list;
automatic Next/wrap and Repeat follow that queue. Browsing does not replace playback.

**Audio change:** selected music uses Master Volume. Music Volume is temporarily muted
while playing and restored on Stop/failure/logout/reload. Read the release notes for
restoration behavior, installation, interruption limits and complete test status.

- [Installable BETA1 ZIP](https://github.com/Scandallisk/MusicSCAN/releases/download/v0.8.0-beta.1/MusicSCAN-0.8.0-BETA1.zip)
- [Release notes](docs/RELEASE-NOTES.md)
- [CurseForge](https://www.curseforge.com/wow/addons/musicscan)
- [Website](https://kilobytes.dev/musicscan/)
- [Issues](https://github.com/Scandallisk/MusicSCAN/issues)
- [Forever is separate](https://github.com/Scandallisk/MusicSCAN-Forever)

Install the MusicSCAN folder in Retail Interface/AddOns; retain WTF/SavedVariables.
Disable MusicSCANPlaybackTest if used, and restart Retail to discover the new modules.
Commands: /msc, play, stop, next, repeat, status, restore, reset, help.
No addon dependencies, bundled music, streaming or guessed-duration timers.

The owner approved the local integration; POC3's principal audio behaviors were tested
in-game. Broader listening/travel coverage remains limited. Theme views reuse stable IDs;
unknown/provisional locations are not guessed into every playlist.

## Development

Python 3.9+ for tooling only:

```sh
python -m pip install -r tests/requirements.txt
python tests/run_lua.py
python tools/build_themes.py --check
python tools/build_release.py
```

Rules: tools/theme-rules.json. Per-track reasons: catalog/THEME-AUDIT.csv.
Provenance: docs/CATALOG.md. Validation: docs/VALIDATION.md.
The packager enforces ten runtime files and the five-module TOC order.

**All Rights Reserved**, per LICENSE.txt. Blizzard assets and third-party metadata retain
their rights. Public source does not grant an open-source license.
