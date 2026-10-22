# MusicSCAN website updates

Observed on 2026-10-22 at https://kilobytes.dev/musicscan/.
No website edits were made. docs/DESCRIPTION.md provides the complete current
public description, installation instructions, command table and patch notes.

## Version and downloads

After the CurseForge file is approved, update the banner to:

**MusicSCAN v0.7.1 BETA is now available. Listen your way with MusicSCAN.**

Change the installation ZIP name to MusicSCAN-0.7.1-BETA.zip. Set compatibility
copy to **Version: MusicSCAN 0.7.1 BETA**. Point the download button to the actual
approved listing; no public listing URL has been assumed here.

## Feature labels

The feature strip still lists Wealth Tracking, iLevel Comparison, Time Played,
Last Played, Warband Tracking and Secure App. Suggested replacement labels:

**Zone Music | Quick Search | Favorites | Play and Stop | Saved Preferences | Minimap Access**

Add this feature to the detailed list:

**Loading-screen recovery.** MusicSCAN restores the active track after loading
screens, restarting it from the beginning. Login and reload remain idle.

The new recovery behavior still needs the client check before public upload.

## Designed for Adventurers

MusicSCAN was built around a simple idea: your favorite Warcraft music should
be easy to find and play. Browse the expansions, save the tracks you love, and
bring Blizzard's zone music along on your adventures across Azeroth.

## Privacy and Data

MusicSCAN stores favorites and player preferences locally using World of
Warcraft's SavedVariables system. It plays music already installed with WoW
and makes no network requests. No external accounts or services are required.

## Development and Feedback

Independently developed by SCAN | Kilobytes Development.
**MusicSCAN — Listen your way.**

Replace the remaining VaultSCAN names and the Less managing More adventuring
tagline in this section with the MusicSCAN copy above.

## Professional Experience

Replace character wealth, item-level, Warband and automated character-statistic
claims in the skills table with these MusicSCAN-specific examples:

| Skill | MusicSCAN example |
| --- | --- |
| World of Warcraft addon development | Building a standalone Retail addon in Lua with native Blizzard frames and audio APIs |
| Product design and feature planning | Keeping music discovery, playback and Favorites focused on a small set of controls |
| User interface design | Creating a movable and resizable music player with collapsible groups and a minimap launcher |
| Music catalog design | Separating file identities from composition names, zones and expansion metadata |
| Data processing | Filtering source music metadata and producing a repeatable catalog build |
| Local data persistence | Saving Favorites and player preferences with SavedVariables |
| Event-driven programming | Restoring an active music request after loading while canceling stale work |
| Quality assurance | Testing catalog integrity, UI behavior and loading recovery with mocked events and timers |
| Technical documentation | Writing player instructions, slash-command references, release notes and beta limitations |
| Release management | Preparing distinct source and installable packages for GitHub and CurseForge |

The unrelated Legends of Aria / Discord / subscription tags at the bottom can
also be replaced with the MusicSCAN skills above.
