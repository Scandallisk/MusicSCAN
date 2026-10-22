# MusicSCAN 0.7.1 BETA catalog

**5,493 individual built-in music FileDataIDs**, expanded from the original 13.
No audio files, sound-effect folders or voice-recording folders are imported.

| Expansion | Entries |
| --- | ---: |
| Original World of Warcraft | 200 |
| The Burning Crusade | 384 |
| Wrath of the Lich King | 514 |
| Cataclysm | 525 |
| Mists of Pandaria | 515 |
| Warlords of Draenor | 300 |
| Legion | 395 |
| Battle for Azeroth | 606 |
| Shadowlands | 648 |
| Dragonflight | 398 |
| The War Within | 504 |
| Midnight | 504 |

## Source and eligibility

The file ID/name source is wowdev/wow-listfile, pinned to commit
`0ed693f708da0bbe4d7e4cdf8c85de5ef3d83b03` (2026-10-02):
https://github.com/wowdev/wow-listfile/blob/0ed693f708da0bbe4d7e4cdf8c85de5ef3d83b03/parts/sound.csv

A frozen lookup retrieved on 2026-10-21 from
https://www.wowhead.com/sounds/zone-music supplies category 28 sound-kit records
and their **files[].id audio FileDataIDs**. The SoundKit record ID is retained
as provenance only; it is never passed to PlayMusic.

The lookup collected 5,960 sound-kit entries and 6,087 distinct file IDs through
untruncated name-filter queries and the initial category listing. This is an
identified-source snapshot, not a complete export of Blizzard's ZoneMusic.db2.
The source category can contain other cues, so category membership alone is not
the import rule. Each new entry must also have a named MP3/OGG under a supported
sound/music zone/expansion folder, and pass the non-background-cue exclusions.

The original thirteen prototype entries retain their exact IDs, keys, names
and locations. Of these, five have explicit user playback confirmations.
Grizzly Hills is preserved on that evidence even where the frozen lookup does
not expose that particular intro file. Playback flags remain developer metadata;
there are **no Test badges or pending-test tooltip labels** in the player.

## What is excluded

All 7,086 sound/music source paths are accounted for as 5,493 included entries
and 1,593 excluded records. Each excluded ID/path has a recorded reason in
`tools/catalog-exclusions.csv`:

| Reason | Count |
| --- | ---: |
| zone-music-category-not-established | 356 |
| not-zone-background-music | 91 |
| expansion-not-established | 5 |
| scene-voice-effect-or-nonbackground-cue | 552 |
| explicit-test-beta-or-unused-name | 8 |
| metadata-not-audio | 191 |
| outside-requested-expansion-folders | 390 |


The rules exclude .meta sidecars, unsupported source branches, explicitly unused/
test/beta cues, scene/RTC/cinematic/voice/effect cues, login/credits, jingles,
event and pet-battle folders. Files outside sound/music never enter the import.
No claim is made that omitted files are absent from the current Retail client.

## Names, variations and locations

Readable labels are cleaned from source names. Technical MUS/version prefixes
are removed; identifiable day/night and arrangement suffixes remain distinct.
Separate files are not merged simply because they share a composition name.
Exact file IDs prevent duplicate entries; repeated cleaned labels receive a
stable alternate suffix within the source snapshot.

Locations are inferred from explicit legacy folders, recognizable modern
filename tokens, or the thirteen curated prototype overrides. The source
filenames can be community assigned. These associations are provisional and do
not mean a composition is used exclusively in one zone. Eligible music with no
established location appears under **Other Zone Music** in its known expansion.
2,865 entries currently use that category; they remain searchable by title.

catalog/CATALOG.csv records each mapping method and original filename, so labels can be
improved without changing the ID-based selection key. It also preserves
SoundKit IDs independently from playback FileDataIDs. The old Temple of the
Jade Serpent baseline label is retained; its reference MP3 title previously
suggested Krasarang Wilds, so that specific identity still needs listening.

## Favorites

Favorites reference existing audio FileDataIDs in SavedVariables. They do not
add, remove or reclassify catalog records. This release preserves all 5,493
entries and their source/mapping data from v0.6.0. Display names can improve
without changing favorite identity.

## Playback evidence and limits

The user has explicitly confirmed Magnificent Desolation, Grizzly Hills,
Suramar, The Dreamer (Variation A), and Boralus. A screenshot alone does not
establish audible identity of another entry. No bulk in-game playback test has
been performed here. Some archived IDs may be unavailable or change in a later
client; the source import is not a guarantee of complete current-client coverage.

MusicSCAN uses PlayMusic(FileDataID), with StopMusic to release its override.
There are no bundled audio files, runtime downloads, duration estimates, replay
loop schedulers, combat/zone selection rules or one-time-playback controls.
A separate one-shot loading-screen recovery can restart the active request.

## Rebuilding

1. Obtain the sound.csv at the exact URL in tools/catalog-source.json.
2. Run `python3 tools/build_catalog.py --source /path/to/sound.csv` from any directory.
3. The generator validates the source SHA256 and rebuilds MusicSCAN/Database.lua,
   catalog/CATALOG.csv, catalog/CATALOG-SOURCE.json and tools/catalog-exclusions.csv.
4. Review generated changes and run tools/build_release.py to regenerate the installable ZIP and checksum.

The frozen zone-category lookup and thirteen overrides are included. Refreshing
upstream lookup data is a separate review step, not a network action performed
by the addon or the build command. No audio downloading is needed.
