# MusicSCAN

<img src="assets/MusicSCAN-badge.png" alt="MusicSCAN black and white circular music badge" width="320">

**Listen your way with MusicSCAN.**

**0.7.1 BETA** · World of Warcraft Retail · SCAN | Kilobytes Development  
[MusicSCAN project page](https://kilobytes.dev/musicscan/)

MusicSCAN brings Blizzard's built-in zone music to wherever you are in Azeroth.
Standing in Stormwind but in the mood for Grizzly Hills? Choose a track and press
**Play**. Press **Stop** when you want normal zone music back.

**Less configuring. More listening.**

## Features

- **A broad music catalog:** 5,493 individual music-file entries across 12 expansion
  categories, from Original World of Warcraft through Midnight.
- **Easy browsing:** expansions in release order, with alphabetical zones and
  tracks. Expand or collapse categories with their + / - controls.
- **Quick search:** find a track, zone or expansion without opening every category.
- **Favorites:** click the star to save the highlighted track. Your alphabetical
  Favorites category sits below the expansion categories; search `Favorites`
  to jump straight to the saved list.
- **Simple playback:** Play starts or restarts the selection; Stop releases the
  music override. WoW handles repetition.
- **Loading-screen recovery:** automatically restore the active track after
  loading, starting again from the beginning.
- **A compact player:** charcoal and black styling, champagne accents and a green
  Now Playing heading. Move the title bar and resize from the bottom-right grip.
- **Minimap access:** click the launcher to open or close; drag it to reposition.
- **Remembered preferences:** account-wide favorites, selection, category folds,
  window size, position and visibility, plus minimap placement.
- **Standalone:** no addon dependencies, bundled audio or network requests.

## Installation

1. Download **MusicSCAN-0.7.1-BETA.zip**, the installable release asset.
2. Exit World of Warcraft.
3. Extract the **MusicSCAN** folder into your Retail installation's
   `World of Warcraft/_retail_/Interface/AddOns/` folder.
4. Confirm the final file path is `AddOns/MusicSCAN/MusicSCAN.toc`.
5. Launch Retail and enable MusicSCAN in the character-selection AddOns list.
6. Open the player with its minimap button or `/musicscan`.

Use the installable ZIP for the game. GitHub's automatic source-code archives
contain development files and are not the installable addon package.

### Upgrading

Exit WoW, keep a rollback copy of your previous release, and replace only the
**MusicSCAN** addon folder. Keep your `WTF` folder and SavedVariables to retain
favorites and preferences. The saved database remains **MusicSCANDB**; this beta
keeps the same track identities and saved settings as the tested 0.7.0 build.
The player footer and title-icon tooltip should show **0.7.1 BETA**.

## Using the player

1. Browse an expansion or search for a zone or title.
2. Select a track and click **Play**. Selecting another row alone does not switch
   the music; click Play when you are ready.
3. Click **Stop** to hand music control back to WoW.

For a first listen, search **Magnificent Desolation** from Warlords of Draenor.
Its audio FileDataID is **936340**, confirmed in-game away from its associated zone.

The star always acts on the **highlighted selection**, including when a different
track is playing. Click an outline star to add that selection to Favorites;
click the filled star to remove it. The tooltip names the target track.
Removing a favorite leaves its normal catalog entry available.

Closing the player, searching, favoriting and collapsing categories leave the
current playback request alone. Login and `/reload` retain preferences but do
not automatically resume MusicSCAN playback. Hover or click the title icon for
author, website and version details; track tooltips show audio FileDataIDs.

## All slash commands

Both `/musicscan` and `/msc` accept every command below.

| Full command | Short alias | Action |
| --- | --- | --- |
| `/musicscan` | `/msc` | Open or close the player |
| `/musicscan play` | `/msc play` | Start or restart the highlighted track |
| `/musicscan stop` | `/msc stop` | Stop the MusicSCAN override and return control to WoW |
| `/musicscan reset` | `/msc reset` | Reset window size and position and minimap placement; show the player |
| `/musicscan help` | `/msc help` | Print the command summary |

Reset preserves favorites and the selected track. Unknown command text also
prints help. There are no timing, playlist or loop commands.

## Patch notes for 0.7.1 BETA

- Restore the active MusicSCAN track after a loading-screen transition.
- Wait for loading to finish, then allow one second for zone audio to initialize.
- Keep the active track even when another row is highlighted.
- Cancel pending restoration on Stop, explicit Play, a subsequent transition or logout.
- Ignore stale callbacks so a canceled request cannot override a later choice.
- Clear the Playing display when recovery fails or Sound / Music is disabled.
- Preserve idle behavior after login and reload, Favorites and the existing catalog.

See CHANGELOG.md for earlier development milestones.

## Loading screens

MusicSCAN restores the track that was playing about one second after a loading
screen closes. Restoration restarts the file from the beginning; it cannot resume
at an exact playback position. The highlighted selection can be different from
the active track. Pressing Stop or Play cancels a pending restoration. Login and
`/reload` remain idle. This new recovery path needs its first Retail client test.

## Beta notes

The catalog is filtered for zone and location background music. Sound effects,
voice recordings and explicit scene / cinematic cues are outside its import
policy. The bulk import has not had a complete in-game listening review: some
files may be silent, unavailable or associated with a name or location that needs
correction. Report the title, expansion and tooltip **FileDataID** when you find one.

Names and locations come from source filenames and curated mappings; they are
not all official soundtrack titles. Separate variations remain separate files.
**Other Zone Music** groups eligible music whose precise zone is not established.
The entry count describes individual files, not 5,493 unique compositions or a
guarantee of every music file in the current client.

PlayMusic repeats in the tested client even with WoW's Loop Music option off.
MusicSCAN has no reliable track-position or completion callback, so this build
uses native repetition with manual Stop. It provides no playback timer, seek bar, loop
toggle or play-once mode. A Playing label records an accepted playback request;
the addon cannot verify audible output or detect all engine interruptions.

Enable Sound and Music in WoW's Audio settings and raise Music Volume if needed.
MusicSCAN does not change global audio settings. If a Lua error occurs, note the
command or action that triggered it and include the error text in your report.

## Credits

Developed by **SCAN | Kilobytes Development**.  
Website: [MusicSCAN project page](https://kilobytes.dev/musicscan/)

Catalog provenance: [wowdev/wow-listfile](https://github.com/wowdev/wow-listfile)
and [Wowhead Zone Music](https://www.wowhead.com/sounds/zone-music), with curated
prototype mappings and direct in-game checks. See SOURCES.md in the addon folder
or docs/CATALOG.md in the source repository for the import policy and snapshot.

World of Warcraft and the music belong to Blizzard Entertainment and their
respective rights holders. MusicSCAN includes identifiers and metadata, not audio.
This is an independent community addon, not an official Blizzard product.


## Source layout and building

- `MusicSCAN/` contains the installable addon. Only Database.lua, MusicSCAN.lua
  and UI.lua are loaded by its TOC, in that order.
- `catalog/` holds reviewable CSV metadata and the pinned source manifest.
- `tools/` holds the offline catalog generator and a small release packager.
- `tests/` holds the mocked Lua regression checks; they do not replace client tests.
- `docs/` holds catalog policy, validation, publishing instructions and page copy.
- `assets/` holds publishing artwork, separate from game files.

Run `python3 tools/build_release.py` from any directory to generate the installable
ZIP and SHA256SUMS.txt under `dist/`. Python is a developer tool only; players do
not need it. See docs/CATALOG.md to rebuild metadata from its pinned input and
docs/VALIDATION.md to run the local regression checks.

Use docs/PUBLISHING.md for GitHub release and CurseForge submission details.
Copyright and permitted use are stated in LICENSE.txt; third-party material
remains subject to its respective rights.
# MusicSCAN
