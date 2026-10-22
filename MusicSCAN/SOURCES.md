# MusicSCAN catalog sources

The addon contains metadata and audio FileDataIDs only. Blizzard's installed
client supplies the audio. There are no bundled music files or runtime downloads.

- wowdev/wow-listfile: https://github.com/wowdev/wow-listfile
- Pinned commit: 0ed693f708da0bbe4d7e4cdf8c85de5ef3d83b03, dated 2026-10-02.
- Source: https://raw.githubusercontent.com/wowdev/wow-listfile/0ed693f708da0bbe4d7e4cdf8c85de5ef3d83b03/parts/sound.csv
- Source SHA256: d2d8df1ac37117654db2e38f3c6a3f4949a30ad859458013dd4316b55d03a417
- Wowhead Zone Music: https://www.wowhead.com/sounds/zone-music
- Lookup snapshot: 2026-10-21, sound category 28, 5,960 SoundKit records and
  6,087 audio FileDataIDs, combined with thirteen curated prototype mappings.

SoundKit IDs and audio FileDataIDs are different identifiers. PlayMusic receives
the audio FileDataID, never a substituted SoundKit ID. Each imported file must
also pass the named music-path and background-music exclusions.

The release retains 5,493 entries across twelve expansion categories. Names and
zone associations are provisional; Other Zone Music holds entries without an
established specific location. The complete library has not been audibly verified
in Retail. This is not a complete export of Blizzard ZoneMusic.db2.

Five audio identities have explicit listening confirmations: Magnificent
Desolation 936340; Grizzly Hills Introduction 229834; Suramar Part 1 1477339;
The Dreamer Variation A 3930252; Boralus Introduction 2175189.

The source repository includes full CSV metadata, exclusion records and an
offline builder in catalog/, tools/ and docs/CATALOG.md. Third-party names and
metadata are credited to their sources, not relicensed as original MusicSCAN work.
World of Warcraft and its music remain the property of their rights holders.
