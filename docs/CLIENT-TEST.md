# MusicSCAN Retail 0.8.0 BETA1 — HOTFIX 1

**Tab out without the track skipping. Keep chat quiet by default.**

Version **0.8.0 BETA1 HOTFIX1** · Target **Retail 12.1.5.70783 / interface 120105**

## Fixed

- Background audio suppression could look like a completed track and cause false
  automatic Next or Repeat requests when tabbing out. Play now temporarily enables
  **Sound in Background** automatically; no menu change is required to use MusicSCAN.
- The previous background-audio preference is retained across the queue and restored
  on Stop, failure, loading suspension and logout/reload. Loading recovery reacquires it.
- Routine playback, completion, loading, initialization and diagnostic/error chat logs
  are now behind **debug mode, OFF by default**. Internal diagnostic history stays bounded.
- A rapid-restart safety cutoff stops repeated interruptions instead of flooding chat
  or endlessly restarting tracks. Two automatic starts within two seconds stop safely;
  this can also stop unusually short consecutive tracks. No guessed song durations.

## Audio settings and debug controls

Selected music continues to follow **Master Volume**. MusicSCAN temporarily sets
**Music Volume** to zero to suppress normal zone music, and restores its previous
value on Stop. Enabling background audio also allows other enabled game sounds
while tabbed out. Explicit Music-slider changes are respected on Stop. Turning
Sound in Background OFF during playback stops the queue and leaves that preference OFF.

Use **/msc restore** to stop and retry pending audio-setting restoration. Saved
restoration markers support reload cleanup. If a hard crash prevents cleanup,
check both Music Volume and Sound in Background manually in WoW Audio settings.

- **/msc debug on** — enable chat diagnostic logs.
- **/msc debug off** — disable them (default).
- **/msc debug** — report the current logging setting.
- **/msc status** and **/msc help** — display requested information even with debug OFF.

The debug preference persists across reloads. Errors are also quiet while debug is
OFF; use status or temporarily enable debug when reporting a playback problem.

## Install / upgrade

1. Stop MusicSCAN and fully exit the appropriate Warcraft client. Back up the addon.
2. Download **MusicSCAN-0.8.0-BETA1-HOTFIX1.zip**, the installable asset from
   [this GitHub release](https://github.com/Scandallisk/MusicSCAN/releases/tag/v0.8.0-beta.1-hotfix.1)
   or the corresponding CurseForge beta once approved. Do not use GitHub's source archive.
3. Replace **MusicSCAN/** under the client's **Interface/AddOns/** so MusicSCAN.toc
   is directly inside it. Keep the folder name and preserve WTF/SavedVariables.
4. Restart the client, open **/msc** and press Play. No background-audio menu setup
   is required. Use **/msc reset** if you want the 760x560 default layout (minimum620x460).

This package is for **Retail**; use the separate package for the other edition.
The footer version-label cleanup is reserved for a future major release.

## Existing 0.8 features retained

The split-screen library, six themed views (Cities, Forests, Taverns, PvP, Dungeons
and Raids), Favorites, Next and Repeat remain. All **5493 catalog entries** are
unchanged. Play captures the current ordered library/search queue; browsing and
Favorite edits leave it unchanged. Next always advances and wraps, even with Repeat
ON. Repeat ON repeats the active track; OFF advances. A selection outside the view
plays alone. Loading recovery restarts the active track; login/reload never autoplay.
Closing the window keeps playback running. No bundled audio, downloads or addon dependencies.

## Validation and limits

The owner confirmed the automatic-background-audio local build resolved the reported
tab-out behavior in Forever, and confirmed Stop restores the prior Sound in Background
setting. The same implementation is included in Retail; this is not a separate native
Retail tab-out confirmation. Quiet-mode changes passed mocked tests but have not been
separately reported tested in-game by the owner.

Lua 5.1/5.4 checks cover background setting ownership, queue continuity, restoration,
failed enable/start/restore, saved-marker reload cleanup, loading/logout, explicit
player changes, quiet defaults and persistent debug mode. Existing catalog, Favorites,
queue and transition checks pass. These are not exhaustive listening or travel tests.
Other sound interruptions can still resemble completion. Filename/zone associations
and additional Forever candidates retain their existing provisional status.

[Report issues](https://github.com/Scandallisk/MusicSCAN/issues) with track title,
FileDataID, client build, exact error and steps; include debug/status output when
appropriate. Avoid account details or full SavedVariables files.

SCAN | Kilobytes Development · https://kilobytes.dev/musicscan/
All Rights Reserved; personal installation/local modification per LICENSE.txt.
Blizzard audio and third-party metadata retain their rights.
