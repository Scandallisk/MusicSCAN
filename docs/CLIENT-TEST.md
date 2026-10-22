# MusicSCAN 0.7.1 BETA client check

1. Exit WoW, replace only the MusicSCAN addon folder, and keep SavedVariables.
   Confirm 0.7.1 BETA in the footer or title-icon tooltip after launching.
2. In a Delve, play Magnificent Desolation. Highlight a different track without
   pressing Play. Hearth to Silvermoon. About one second after loading closes,
   Magnificent Desolation should restart; the highlighted track should stay selected.
3. Repeat with a portal or instance entrance. Close the player before traveling
   once; it should restore music with the window closed too.
4. After a transition, immediately click Stop during the short recovery delay.
   The addon must stay stopped. Starting a different track during the delay must
   keep that new track instead of restoring the earlier one.
5. Stop before another loading screen. Normal zone music should remain in control.
6. While playing, use /reload. MusicSCAN should remain idle, retain Favorites
   and selection, and let normal WoW music play. Check a fresh login too.

Report any unexpected restarts, silent playback or Lua errors, including the
travel route, track title and tooltip FileDataID. Loading recovery is locally
tested, but real audio-engine recovery is not yet confirmed in this release.
