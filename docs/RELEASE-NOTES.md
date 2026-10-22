# MusicSCAN 0.7.1 BETA

2026-10-22

- Restore the active track after loading screens, allowing one second for zone audio to initialize.
- Keep the active track when another row is highlighted; restart the file from the beginning.
- Cancel pending restoration on Stop, explicit Play, a subsequent transition or logout.
- Reject stale callbacks so canceled work cannot override a later playback choice.
- Clear the Playing display when recovery fails or Sound or Music is disabled.
- Keep login and reload idle, and retain Favorites, layout preferences and the existing catalog.

Beta: the imported catalog still needs a full in-game listening review. Report incorrect or silent tracks with their title, expansion and tooltip FileDataID.
