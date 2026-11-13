# MusicSCAN Retail — 0.8.0 BETA1

Retail BETA release for 12.1.5.70783, interface 120105.
Forever is a separate product/build and is not changed by this package.

## New player

Left: All Music, Favorites, Cities, Forests, Taverns, PvP, Dungeons, Raids and expansions.
Right: tracks from the chosen library, with search and chronological expansion/zone groups.
The sidebar and track pane scroll independently. Minimum window size is 620 x 460;
default is 760 x 560. Existing valid larger geometry is retained. /msc reset uses the new default.

Play starts the highlighted track and captures the current displayed list, including its
search filter, as a fixed queue. Category folds only affect display, not membership.
If a previously selected track is outside the current view, Play uses that track alone.
Changing library, search, selection, folds or Favorites during playback does not alter the
captured queue. Press Play again to start the selected track with the new queue.

Next immediately advances in the active queue and wraps to its first track at the end.
Repeat ON repeats the active track on completion. OFF advances. Next always advances.
Favorites always target the highlighted selection, independently of the active track.
Closing the window preserves playback. Login and /reload stay idle.

## Audio behavior — important

This build integrates the user-confirmed POC3 approach: tracks play on the MASTER channel.
MASTER VOLUME controls track loudness. While active, only WoW Music volume is temporarily
set to zero to suppress normal zone music; its exact old value is restored on Stop,
failure, logout/reload and when playback suspends for loading. Recovery reacquires the mute.
The original volume is retained between queue items. A saved restoration marker supports
reload cleanup; /msc restore stops the player and retries restoration. Manual Music-volume
changes made during playback are respected on Stop. Raising Music volume while playing
will make normal zone music audible again. Other audio sliders are not changed.

No guessed song durations are used. A 0.2-second watcher is active only during playback
and detects the track handle changing from playing to stopped. This cannot distinguish
every interruption/voice-stealing event from a natural ending. Loading events are gated
to suspend rather than advance, then restart the active track after the transition.
Failed starts stop the queue; they do not cause endless retry/skipping of unavailable files.

The prior two-track POC3 was confirmed in-game for zone suppression, restoration, automatic
Next, Next/wrap and Repeat. The owner approved the integrated local build. Full-library listening and all travel/reload
edge cases have not been independently verified.

## Test this local build

1. Stop any existing MusicSCAN or /msctest playback, then fully exit/restart Retail.
   The standalone playback test's TOC is disabled by this install to prevent competition.
2. Open /msc. Confirm 0.8.0 BETA1 in the footer; use /msc reset if a larger layout is wanted.
3. In Cities, search Boralus, select Introduction and Play. Confirm no zone-music overlap.
4. For a short two-track queue, favorite Boralus Introduction and The Dreamer Variation A.
   Open Favorites, clear search and Play Boralus. Wait for automatic Next; test Next and Repeat.
5. While playing, change sources/search and highlight another track: audio and queue stay intact.
   Press Play to deliberately adopt that view. /msc status reports the captured source/count.
6. Stop: previous Music volume and normal zone music return. Test this before further checks.
7. Hearth/portal with active A and highlighted B: active A should restart after loading.
   Stop during loading/recovery must prevent it. /reload must leave playback idle and restore Music.
8. Check window movement/resizing, both scrollers, minimap, search and saved Favorites after reload.

Commands: /msc or /musicscan; play, stop, next, repeat, status, restore, reset and help.
Release notes: https://github.com/Scandallisk/MusicSCAN/releases/tag/v0.8.0-beta.1
CurseForge: https://www.curseforge.com/wow/addons/musicscan

Preserve WTF/SavedVariables when updating or rolling back. Stop first, then exit Retail
before restoring the backed-up addon folder. If a hard crash prevents restoration, adjust
Music Volume manually in WoW Audio settings; recovery cannot be guaranteed after all crashes.

SCAN | Kilobytes Development. All Rights Reserved. See LICENSE.txt.
