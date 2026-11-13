MusicSCAN Retail 0.8.0 BETA1 — release candidate, November 13, 2026.

Installed ten-file addon: Retail Interface/AddOns/MusicSCAN.
All installed files hash-match the packaged runtime. ZIP integrity/root/load order checked.
Rollback copies of Retail 0.7.1 and standalone POC3: before-install/ under this deliverable.
Standalone MusicSCANPlaybackTest.toc renamed .toc.disabled to prevent startup competition.
No SavedVariables files, original source checkout or Forever code/install were edited.
GitHub/CurseForge/website publication is being coordinated.

Catalog: all 5,493 records retained byte-for-byte in Database.lua.
Theme views: Cities 174; Forests 376; Taverns 54; PvP 40; Dungeons 213; Raids 396.
Reviewed membership rules and per-track reasons accompany this build outside the runtime folder.
Themes reuse stable keys and can overlap. Unmapped/uncertain records remain in All Music;
theme completeness and every audio/zone association have not been independently verified.

Lua 5.1 and 5.4 mocked integration checks passed:
- Native split UI/sidebar/controls construct; visible track frame reuse remains bounded.
- Catalog/theme counts and unique IDs; existing selection, Favorites, geometry, minimap retained.
- Exact current-view queue order; browsing/search/Favorite edits cannot mutate captured queue.
- Repeat and loading recovery preserve independently highlighted B while active A continues.
- Automatic Next, explicit Next/wrap, Repeat, frozen Favorites queue and stopped state.
- Temporary Music volume suppression/restoration, user volume adjustments and saved marker cleanup.
- Muted/rejected audio, canceled/stale recovery, idle login/reload and literal punctuation search.
- Minimum-size 620x460 UI layout logic exercised; actual client rendering remains unverified.

User-confirmed audio baseline: POC3 suppresses zone music, restores it with Stop,
advances Boralus to Dreamer, wraps with Next and repeats with Repeat ON.
Owner approved the integrated local build. Full-library listening/all recovery paths remain unverified.
Track output follows Master Volume. Native handle termination is not proof of natural
completion in every interruption case. Stop must restore Music volume before further testing.
