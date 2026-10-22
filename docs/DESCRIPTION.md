# MusicSCAN

**Listen your way with MusicSCAN.**

**0.7.1 BETA** | World of Warcraft Retail | SCAN | Kilobytes Development

Bring your favorite Blizzard zone music with you. MusicSCAN is a standalone World of Warcraft Retail addon that lets you choose built-in music wherever you are in Azeroth. Listen to Grizzly Hills while standing in Stormwind, or settle in with Magnificent Desolation from Warlords of Draenor.

Choose a track and press Play. Press Stop to return control to WoW's normal zone music. Less configuring. More listening.

## Features

- **Browse across expansions:** Explore 5,493 individual music-file entries across 12 expansion categories, from Original World of Warcraft through Midnight.
- **Find music quickly:** Expansions follow release order; zones and tracks are alphabetical. Expand or collapse categories and search by title, zone or expansion.
- **Keep your favorites:** Click the star to save the highlighted track. The alphabetical Favorites category sits below the expansions and remembers your saved tracks across reloads.
- **Restore music after loading:** The active track restarts about one second after loading finishes, including when another track is highlighted. Pressing Stop or Play cancels a pending restoration.
- **Make room for listening:** Move the compact charcoal player by its title bar and resize from the bottom-right grip. The minimap launcher is draggable too.
- **Pick up where you left off:** Account-wide preferences remember your selection, favorites, category folds, window layout and minimap placement. Login and reload do not start playback automatically.
- **Use the music already in WoW:** No addon dependencies or bundled audio. MusicSCAN makes no network requests and leaves your global audio settings unchanged.

## Using Favorites

The star acts on the highlighted selection, even when another track is playing. Click the filled star to remove that selection from Favorites; its main library entry stays available. Search Favorites to show your saved list directly. Selecting a different row alone does not change the current music.

## Installation

1. Download MusicSCAN-0.7.1-BETA.zip, the installable release asset.
2. Exit World of Warcraft.
3. Extract the MusicSCAN folder into World of Warcraft/_retail_/Interface/AddOns/.
4. Check that the final path is AddOns/MusicSCAN/MusicSCAN.toc, without an extra nested folder.
5. Launch Retail and enable MusicSCAN in the character-selection AddOns list.
6. Open the player using its minimap button or /musicscan. Select a track, then click Play.

Use the installable release ZIP rather than GitHub’s automatic source-code archive.

### Upgrading

For an upgrade, keep a rollback copy and replace only the MusicSCAN addon folder while WoW is closed. Keep the WTF folder and SavedVariables to retain favorites and preferences. The database is still MusicSCANDB. Confirm 0.7.1 BETA in the player footer or title-icon tooltip.

## All slash commands

Both aliases accept the same subcommands.

| Command and alias | Action |
| --- | --- |
| `/musicscan` or `/msc` | Open or close the player. |
| `/musicscan play` or `/msc play` | Start or restart the highlighted track. |
| `/musicscan stop` or `/msc stop` | Release the MusicSCAN override and return music control to WoW. |
| `/musicscan reset` or `/msc reset` | Restore the default window size and position and minimap placement; show the player. Keep favorites and selection. |
| `/musicscan help` or `/msc help` | Print the command summary. Unknown command text also shows help. |

## Patch notes

**0.7.1 BETA — 2026-10-22**

- Restore the active track after loading screens, allowing one second for zone audio to initialize.
- Keep the active track when another row is highlighted; restart the file from the beginning.
- Cancel pending restoration on Stop, explicit Play, a subsequent transition or logout.
- Reject stale callbacks so canceled work cannot override a later playback choice.
- Clear the Playing display when recovery fails or Sound or Music is disabled.
- Keep login and reload idle, and retain Favorites, layout preferences and the existing catalog.

## Beta notes

**Loading recovery.** The new recovery path has passed mocked event and timer checks. Its actual audio behavior still needs a Retail Delve-to-Silvermoon hearth test before public upload. The file restarts; exact playback-position restoration is unavailable.

**Catalog review.** The library is filtered for zone and location background music, with sound effects, voice recordings and explicit cinematic or scene cues outside the import policy. The bulk import has not had a complete in-game listening review. Some files may be unavailable, silent or need naming and location corrections.

**Names and variations.** The 5,493 entries are individual audio files, not a count of unique compositions or a guarantee of every current-client music file. Friendly names and zone associations are source-derived and provisional. Other Zone Music holds eligible music without an established specific zone.

**Native repetition.** WoW repeats PlayMusic requests in the tested client, even with its Loop Music option off. This beta provides manual Stop without estimated timing, a seek bar, loop controls or play-once playback. Playing reports an accepted request; MusicSCAN cannot verify audible output or detect every engine interruption.

**Audio and feedback.** Enable Sound and Music in WoW's Audio settings and check Music Volume. For an incorrect or silent entry, report its title, expansion and tooltip FileDataID. For Lua errors, include the error text and the action that triggered it.

## Credits

Developed by SCAN | Kilobytes Development. Visit https://kilobytes.dev/musicscan/. Catalog sources include wowdev/wow-listfile and Wowhead Zone Music, with curated mappings and direct in-game checks. World of Warcraft and its music belong to Blizzard Entertainment and their respective rights holders. MusicSCAN is an independent community addon and includes no audio files.

Source credits: https://github.com/wowdev/wow-listfile and https://www.wowhead.com/sounds/zone-music.
