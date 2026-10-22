# MusicSCAN 0.7.1 BETA validation

## Prior Retail client confirmations

The 0.7.0 baseline was confirmed for Magnificent Desolation away from its zone,
Stop returning zone music, Grizzly Hills to Suramar switching, playback with the
window hidden, resizing, saved window / minimap placement, and Favorites across reload.
The reported loading-screen interruption is the defect addressed in 0.7.1.

## Local checks for this release

Run `python3 tests/run_lua.py`. Python and liblua5.4.so.0 are development-only
requirements. The suite mocks WoW events, native UI frames, timers and audio calls;
it is not an audio-engine or client compatibility test.

The suite checks all 5,493 catalog identities, stable original keys, chronological
expansions, alphabetical browsing and Favorites, literal search, temporary folds,
preference cleanup, geometry, and bounded native-frame reuse for large lists.

New lifecycle cases cover idle travel, login / reload exclusion, a long loading
screen, active versus selected tracks, restoration with a hidden window, Stop
during loading and the delay, explicit Play of a new or the same track, stale
callbacks, consecutive loads, reversed finish / world-entry ordering, duplicate
events, disabled audio, rejected and throwing playback calls, logout and
reinitialization. Time is advanced deterministically. No polling or playback-
duration scheduling is introduced.

The delay is one second after both world entry and loading-screen completion.
If no loading-screen start is observed, world entry can schedule the recovery.
There is at most one pending recovery timer; cancellation invalidates its callback.

## Packaging checks

Local regression and packaging results: PASS on 2026-10-22.

The UI source is unchanged from 0.7.0 BETA. Catalog metadata records and input
snapshots remain unchanged; only the generated database version comment changes.
The beta preserves MusicSCANDB and introduces no new saved playback setting.

The release packager permits eight addon files and verifies the TOC loads only
Database.lua, MusicSCAN.lua and UI.lua. It produces a deterministic ZIP under a
single MusicSCAN root and a SHA256 checksum. Tools, tests, metadata exports,
publishing assets and the Word document remain outside the installable ZIP.

## Retail check still required

Run docs/CLIENT-TEST.md before public upload. Local tests pass for recovery logic;
the one-second delay and actual restored audio still need the Delve-to-Silvermoon
test in WoW. Do not describe this release as an in-game-confirmed recovery yet.

The working Interface 120105 value is retained. The imported catalog still needs
a full listening review; only five track identities have explicit listening
confirmations in its metadata. No Classic or blanket future-build support is claimed.

## Primary API references

- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/LoadingScreenDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UITimerDocumentation.lua
