# MusicSCAN 0.8.0 BETA1 — Retail

**Less configuring. More listening.**

## What's new

- Split library sidebar and track pane with independent scrolling.
- Cities (174), Forests (376), Taverns (54), PvP (40), Dungeons (213), and Raids (396).
- All 5,493 original catalog records, selection keys and Favorite IDs retained.
- Play captures the current ordered library/search results as a fixed playback queue.
- Automatic Next and explicit Next advance through the queue, wrapping at the end.
- Repeat ON repeats the active track; Next always advances. Repeat OFF sequences the list.
- Browsing, search, selection and Favorite edits leave the captured queue unchanged.
- Loading recovery restarts active A while preserving a different highlighted row B.
- Login/reload stay idle. Native frame reuse keeps large-library browsing bounded.

## Audio change — please read

Selected tracks now follow **Master Volume**. MusicSCAN temporarily sets only **Music
Volume** to zero while active to suppress normal zone music, retaining its exact old
value. Stop, failure, logout/reload and loading suspension restore it; recovery reacquires
suppression. Other audio sliders are unchanged. A player's Music-volume adjustment made
during playback is respected on Stop; raising that slider makes zone music audible again.
Use **/msc restore** to stop and retry a pending restoration. If a hard crash prevents
cleanup, restore Music Volume manually in WoW Audio settings.

No guessed durations, downloaded/bundled audio or addon dependencies. A 0.2-second handle
watcher runs only during playback. A 30-second startup watchdog safely stops a file never
observed playing. Handle termination cannot distinguish every interruption from a natural
ending. Failed files stop the queue rather than causing endless skipping/retries.

## Installation

Download **MusicSCAN-0.8.0-BETA1.zip**, not GitHub's automatic source-code archive.
Stop MusicSCAN and /msctest if installed, then fully exit Retail. Replace the MusicSCAN
folder under `_retail_/Interface/AddOns/`, with MusicSCAN.toc directly inside it.
Preserve WTF/SavedVariables, MusicSCANDB and the folder name. Disable the standalone
MusicSCANPlaybackTest addon if previously used. Fully restart to discover the new modules.

Open **/msc** or **/musicscan**. Use **/msc reset** for the new 760x560 default window;
minimum size is 620x460. Choose a library and track, then Play. If the selected track is
outside the current view, Play uses that selection alone. Favorites target the highlighted
row; Repeat targets the active track. Closing the window keeps audio playing.
Commands: play, stop, next, repeat, status, restore, reset, help.

## Testing and limits

The owner confirmed POC3 in-game: zone suppression, Stop restoration, automatic Boralus
to Dreamer, Next/wrap and Repeat. The owner also approved the integrated local build.
Mocked Lua 5.1/5.4 tests pass for catalog identities, themed libraries, split native UI,
queue stability, Favorites, Next/Repeat, loading/cancellation and volume restoration.
This is not a complete listening review or validation of every travel route/client build.
Theme assignments are reviewed metadata associations, not exhaustive official playlists.
Unknown locations remain in All Music and existing provisional labels remain provisional.

Target: **Retail 12.1.5.70783**, interface **120105**. Forever remains a separate release;
no Classic/Forever compatibility is claimed for this ZIP.

## Feedback and rights

[Report issues](https://github.com/Scandallisk/MusicSCAN/issues) with title, location,
FileDataID, client build, exact Lua error and steps. Include library/search/Repeat state
for queue issues, and travel route for recovery issues. Do not attach account details
or full SavedVariables files.

SCAN | Kilobytes Development — https://kilobytes.dev/musicscan/
All Rights Reserved; personal installation/local modification per LICENSE.txt. Blizzard
audio and third-party metadata retain their rights. Public source is not an open-source license.
