# Catalog and audio provenance

Database.lua is retained unchanged from MusicSCAN Retail 0.7.1 BETA: 5,493 unique
audio FileDataIDs across 12 expansion categories. Original selection keys, Favorites
identities and metadata are preserved. No Blizzard audio, downloaded music or silent
carrier is packaged. The addon plays files distributed with the user's installed client.

Underlying metadata source: wowdev/wow-listfile, parts/sound.csv, revision
0ed693f708da0bbe4d7e4cdf8c85de5ef3d83b03; pinned SHA256
d2d8df1ac37117654db2e38f3c6a3f4949a30ad859458013dd4316b55d03a417.
Original catalog eligibility additionally used frozen zone-music-category lookups and
prototype overrides documented in the Retail source repository.

Themes.lua contains views referencing those existing keys. Initial counts: Cities 174,
Forests 376, Taverns 54, PvP 40, Dungeons 213, Raids 396. Membership uses explicitly
listed zone labels and filename tokens, not generic substring matches on player input.
Unmapped music remains in All Music. Multiple theme memberships are permitted; no new
audio records or duplicate IDs are created. These are curated metadata associations,
not official soundtrack categories, complete zone coverage or bulk listening verification.
Known naming/zone imperfections in the source catalog remain provisional.

Authoring records THEME-RULES.json and THEME-AUDIT.csv accompany the local test deliverable
outside the runtime folder, so theme assignments can be reviewed and corrected.

World of Warcraft and its audio are Blizzard assets. Third-party metadata retains its
own rights. Original addon code is All Rights Reserved; see LICENSE.txt.
