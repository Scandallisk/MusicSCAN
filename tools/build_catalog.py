#!/usr/bin/env python3
"""Build static MusicSCAN metadata. Standard library only; never run by WoW.

Usage: python3 tools/build_catalog.py --source path/to/sound.csv
The exact source URL and SHA256 are recorded in tools/catalog-source.json.
"""
import argparse
import csv
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPANSIONS = ["Original World of Warcraft", "The Burning Crusade", "Wrath of the Lich King",
              "Cataclysm", "Mists of Pandaria", "Warlords of Draenor", "Legion",
              "Battle for Azeroth", "Shadowlands", "Dragonflight", "The War Within", "Midnight"]
FOLDERS = dict(zip(["cataclysm", "pandaria", "draenor", "legion", "battleforazeroth",
                   "shadowlands", "dragonflight", "warwithin", "midnight"], EXPANSIONS[3:]))
BC_ZONES = {
    "azuremyst": "Azuremyst Isle", "blacktemple": "Black Temple", "bladesedge": "Blade's Edge Mountains",
    "bloodmyst": "Bloodmyst Isle", "cavernsoftime": "Caverns of Time", "eversong": "Eversong Woods",
    "ghostlands": "Ghostlands", "hellfirepeninsula": "Hellfire Peninsula", "karazhan": "Karazhan",
    "nagrand": "Nagrand (Outland)", "netherstorm": "Netherstorm", "outlandgeneral": "Outland",
    "shadowmoonvalley": "Shadowmoon Valley (Outland)", "sunwell": "Sunwell Plateau",
    "tempestkeep": "Tempest Keep", "terokkar": "Terokkar Forest", "zangarmarsh": "Zangarmarsh",
    "zulaman": "Zul'Aman", "brewfest": "Brewfest", "dmf_l70etc01.mp3": "Darkmoon Faire",
}
WRATH_ZONES = {
    "boreantundra": "Borean Tundra", "dragonblight": "Dragonblight", "howlingfjord": "Howling Fjord",
    "grizzlyhills": "Grizzly Hills", "azjolnerub": "Azjol-Nerub", "chamberoftheaspects": "Chamber of Aspects",
    "crystalsong": "Crystalsong Forest", "dalaran": "Dalaran (Northrend)", "ebon hold": "Acherus: The Ebon Hold",
    "icecrownglacier": "Icecrown", "lakewintergrasp": "Wintergrasp", "nexus": "The Nexus",
    "northrend": "Northrend", "sholazarbasin": "Sholazar Basin", "stormpeaks": "The Storm Peaks",
    "stratholmepast": "The Culling of Stratholme", "ulduar": "Ulduar", "utgarde keep": "Utgarde Keep",
    "violethold": "The Violet Hold", "zuldrak": "Zul'Drak", "ulduarraidext": "Ulduar",
    "ulduarraidint": "Ulduar", "argenttournament": "Argent Tournament", "argentcoliseum": "Trial of the Crusader",
    "icecrownraid": "Icecrown Citadel",
}
LEGACY_ZONES = {
    "ahnqiraj": "Ahn'Qiraj", "naxxramas": "Naxxramas", "pvp": "Battlegrounds",
    "barrendry": "Shared Landscapes: Barren Lands", "cursedland": "Shared Landscapes: Cursed Lands",
    "desert": "Shared Landscapes: Desert", "enchantedforest": "Shared Landscapes: Enchanted Forest",
    "evilforest": "Shared Landscapes: Dark Forest", "forest": "Shared Landscapes: Forest",
    "ghostmusic": "Ghost World", "jungle": "Shared Landscapes: Jungle", "mountain": "Shared Landscapes: Mountains",
    "plains": "Shared Landscapes: Plains", "soggyplace": "Shared Landscapes: Marshes", "volcanic": "Shared Landscapes: Volcanic",
    "tavernalliance": "Alliance Taverns", "taverndwarf": "Dwarven Taverns", "tavernhorde": "Horde Taverns",
    "tavernhuman": "Human Taverns", "tavernnightelf": "Night Elf Taverns", "tavernorc": "Orcish Taverns",
    "tavernpirate": "Pirate Taverns", "taverntauren": "Tauren Taverns", "tavernundead": "Undead Taverns",
}

# Conservative filename associations, not an exhaustive claim of in-game usage.
# More specific expressions precede broader regions. Unmatched themes stay unassigned.
LOCATION_RULES = {
    "cataclysm": [
        ("guardiansofhyjal|mount hyjal|hyjal", "Mount Hyjal"), ("vashjir|vashj", "Vashj'ir"),
        ("twilighthighlands", "Twilight Highlands"), ("uldum", "Uldum"), ("deepholm", "Deepholm"),
        ("gilneas", "Gilneas"), ("kezan", "Kezan"), ("lostisles", "The Lost Isles"),
        ("dragonsoul", "Dragon Soul"), ("firelands", "Firelands"), ("grim batol|grimbatol", "Grim Batol"),
        ("zulaman|_za_", "Zul'Aman"), ("zulgurub|_zg_", "Zul'Gurub"),
        ("southernbarrens", "Southern Barrens"), ("northernbarrens", "Northern Barrens"),
        ("arathihighlands", "Arathi Highlands"), ("darkshore", "Darkshore"), ("ashenvale", "Ashenvale"),
        ("azshara", "Azshara"), ("tanaris", "Tanaris"), ("feralas", "Feralas"), ("mulgore", "Mulgore"),
        ("teldrassil", "Teldrassil"), ("silverpine", "Silverpine Forest"), ("hillsbrad", "Hillsbrad Foothills"),
        ("dunmorogh", "Dun Morogh"), ("elwynn", "Elwynn Forest"), ("westfall", "Westfall"),
        ("redridge", "Redridge Mountains"), ("stranglethorn", "Stranglethorn Vale"),
        ("ironforge", "Ironforge"), ("orgrimmar", "Orgrimmar"), ("durotar", "Durotar"),
        ("stormwind", "Stormwind"), ("undercity", "Undercity"), ("thunderbluff", "Thunder Bluff"),
        ("wetlands", "Wetlands"), ("lochmodan", "Loch Modan"), ("searinggorge", "Searing Gorge"),
        ("burningsteppes", "Burning Steppes"), ("thousandneedles", "Thousand Needles"),
        ("stonetalon", "Stonetalon Mountains"), ("desolace", "Desolace"), ("winterspring", "Winterspring"),
        ("felwood", "Felwood"), ("ungoro", "Un'Goro Crater"), ("badlands", "Badlands"),
        ("easternplague|eastplague", "Eastern Plaguelands"), ("westernplague|westplague", "Western Plaguelands"),
    ],
    "pandaria": [
        ("templeofthejadeserpent", "Temple of the Jade Serpent"), ("jadeforest", "The Jade Forest"),
        ("kunlai", "Kun-Lai Summit"), ("valleyofthefourwinds|fourwinds", "Valley of the Four Winds"),
        ("krasarang", "Krasarang Wilds"), ("townlong", "Townlong Steppes"), ("dreadwastes", "Dread Wastes"),
        ("eternalblossoms|_veb_", "Vale of Eternal Blossoms"), ("thunderisle|thunderking|isleofthunder", "Isle of Thunder"),
        ("timelessisle", "Timeless Isle"), ("siegeoforgrimmar", "Siege of Orgrimmar"),
        ("mogushan", "Mogu'shan Vaults"), ("heartoffear", "Heart of Fear"),
        ("scholomance", "Scholomance"), ("scarletmonastery", "Scarlet Monastery"),
        ("serpentsheart", "Serpent's Heart"), ("wanderingisle", "The Wandering Isle"),
    ],
    "draenor": [
        ("magnificentdesolation|frostfire", "Frostfire Ridge"), ("nagrand", "Nagrand (Draenor)"),
        ("gorgrond", "Gorgrond"), ("talador", "Talador"), ("spiresofarak", "Spires of Arak"),
        ("shadowmoon", "Shadowmoon Valley (Draenor)"), ("tanaan", "Tanaan Jungle"), ("ashran", "Ashran"),
        ("garrison", "Garrison"), ("auchindoun", "Auchindoun"), ("skyreach", "Skyreach"),
        ("highmaul", "Highmaul"), ("blackrockfoundry", "Blackrock Foundry"), ("hellfirecitadel", "Hellfire Citadel"),
    ],
    "legion": [
        ("suramar", "Suramar"), ("highmountain", "Highmountain"), ("azsuna", "Azsuna"),
        ("valsharah|nossharah", "Val'sharah"), ("stormheim", "Stormheim"), ("dalaran", "Dalaran (Broken Isles)"),
        ("brokenshore", "Broken Shore"), ("karazhan", "Karazhan"), ("tombofsargeras", "Tomb of Sargeras"),
        ("seatofthepantheon", "Seat of the Pantheon"), ("antorus", "Antorus, the Burning Throne"),
        ("krokuun", "Krokuun"), ("macaree", "Mac'Aree"), ("antoran", "Antoran Wastes"), ("argus", "Argus"),
        ("emeraldnightmare", "The Emerald Nightmare"), ("hallsofvalor", "Halls of Valor"),
        ("blackrook", "Black Rook Hold"), ("darkheart", "Darkheart Thicket"), ("vaultofthewardens", "Vault of the Wardens"),
    ],
    "battleforazeroth": [
        ("boralus", "Boralus"), ("dazaralor", "Dazar'alor"), ("zuldazar", "Zuldazar"),
        ("voldun", "Vol'dun"), ("nazmir", "Nazmir"), ("tiragarde", "Tiragarde Sound"),
        ("drustvar", "Drustvar"), ("stormsong", "Stormsong Valley"), ("kultiras", "Kul Tiras"),
        ("zandalar", "Zandalar"), ("nazjatar", "Nazjatar"), ("mechagon", "Mechagon"),
        ("nyalotha", "Ny'alotha"), ("uld ir|uldir", "Uldir"), ("darkshore", "Darkshore"),
        ("arathibasin", "Arathi Basin"), ("arathi_highlands|arathihighlands|arathiwarfront", "Arathi Highlands"), ("lordaeron", "Lordaeron"),
    ],
    "shadowlands": [
        ("_aw_|ardenweald", "Ardenweald"), ("_ba_|bastion", "Bastion"),
        ("_mx_|maldraxxus", "Maldraxxus"), ("_rd_|revendreth", "Revendreth"),
        ("zereth|progenitor", "Zereth Mortis"), ("korthia", "Korthia"), ("oribos", "Oribos"),
        ("torghast", "Torghast"), ("_maw_|themaw", "The Maw"), ("tazavesh", "Tazavesh"),
    ],
    "dragonflight": [
        ("azurespan", "The Azure Span"), ("ohnahr|maruuk", "Ohn'ahran Plains"),
        ("wakingshores|waking_shores", "The Waking Shores"), ("thaldraszus", "Thaldraszus"),
        ("valdrakken", "Valdrakken"), ("forbiddenreach", "The Forbidden Reach"),
        ("zaralek", "Zaralek Cavern"), ("amirdrassil|dreamshope", "Amirdrassil"),
        ("viridescent_thicket|emerald_dream|dreams_hope", "Emerald Dream"),
        ("algethar", "Algeth'ar Academy"), ("ruby_life|rubylife", "Ruby Life Pools"),
    ],
    "warwithin": [
        ("hallowfall", "Hallowfall"), ("dornogal", "Dornogal"), ("isle_of_dorn|dorn_country", "Isle of Dorn"),
        ("ringing_deeps|ringingdeep", "The Ringing Deeps"), ("azjkahet|azj_kahet", "Azj-Kahet"),
        ("nerubar", "Nerub-ar Palace"), ("undermine|bilgewater|steamwheedle", "Undermine"),
        ("karesh|ka_resh", "K'aresh"), ("cinderbrew", "Cinderbrew Meadery"),
        ("darkflame", "Darkflame Cleft"), ("dawnbreaker", "The Dawnbreaker"),
    ],
    "midnight": [
        ("silvermoon", "Silvermoon City"), ("eversong", "Eversong Woods"), ("harandar", "Harandar"),
        ("zulaman|zul_aman", "Zul'Aman"), ("voidstorm", "Voidstorm"), ("sunwell", "Sunwell Plateau"),
        ("magisters_terrace|magistersterrace", "Magisters' Terrace"), ("murder_row", "Murder Row"),
        ("housing", "Player Housing"),
    ],
}

COMMON = set("a an the of on in at to for from by with and or as is all it its our your their this that we are be beyond into under over after before soon day night walk walking intro introduction ambient ambience hero heroic main title theme part music battle combat city forest mountain heart soul shadow light wind storm fire water earth blood magic dark deep valley shore isle island hills river village home world ancient sacred quiet magnificent desolation guardians journey rebirth choice dreamer dreams hope fear doubt death life song nightfall twilight dawn echoes fate honor glory peace war return lost forgotten unbroken broken fall rise rising lament will hold restless spirit spirits sun moon winter spring summer autumn first last one two three four five six seven eight nine ten human orc elf dwarves tauren troll gnome alliance horde king queen man woman sea frost ruins explorer patrol general ending march temple halls throne dungeon raid opening victory mystery mysterious wrath ash embers mist eternal burning awakening awakened time centuries times stars sky skies blessed sanctuary salvation warriors warrior warriorsjourney patience point mournings rest serene celestial cosmic cosmicwar veil void nadir whispers whispering sacred souls roots cradle emerald sapphire jade crimson amber golden silver bronze steel iron stone sand swamp marsh plains tundra jungle cavern caverns hall plateau harbor harbour eternal final ritual rivers warriors saints echoes sound silent silence".split())

def make_vocabulary(paths):
    words = set(COMMON)
    for path in paths:
        stem = Path(path).stem
        # Mixed-case source names carry useful word boundaries; don't learn
        # opaque lowercase concatenations as whole English words.
        if re.search(r"[a-z][A-Z]", stem):
            words.update(w.lower() for w in re.findall(r"[A-Z]?[a-z]+", stem) if len(w) > 1)
    for rules in LOCATION_RULES.values():
        for _, label in rules:
            words.update(re.findall(r"[a-z]+", label.lower()))
    return words

def split_word(word, vocabulary):
    word = word.lower()
    if word in vocabulary or len(word) < 6:
        return [word]
    best = {0: []}
    for end in range(1, len(word) + 1):
        choices = [best[start] + [word[start:end]] for start in range(end)
                   if start in best and word[start:end] in vocabulary and
                   (end-start > 1 or word[start:end] in ("a", "i"))]
        if choices:
            best[end] = min(choices, key=lambda parts: len(parts))
    return best.get(len(word), [word])

def friendly(raw, vocabulary):
    raw = re.sub(r"([a-z])([A-Z])", r"\1 \2", raw)
    raw = re.sub(r"\b([A-Za-z]{3,})ofthe(?=\s)", r"\1 of the", raw)
    raw = re.sub(r"\b([A-Za-z]{3,})(of|for)(?=\s)", r"\1 \2", raw)
    raw = re.sub(r"([A-Za-z])(\d)|([0-9])([A-Za-z])", r"\1\3 \2\4", raw)
    words = []
    for part in re.split(r"[_\s-]+", raw):
        if part:
            words.extend(split_word(part, vocabulary))
    small = {"of", "the", "and", "for", "in", "on", "to", "with", "as", "at"}
    return " ".join(w if i and w in small else w.capitalize() for i, w in enumerate(words)).strip()

def classify(path):
    bits = path.lower().split("/"); folder = bits[2]; stem = Path(path).stem.lower()
    if folder in FOLDERS:
        expansion = FOLDERS[folder]
        for pattern, zone in LOCATION_RULES.get(folder, []):
            if re.search(pattern, stem): return expansion, zone, "filename-association"
        if re.search(r"(?:^|_)(rtc|scene|cinematic)(?:_|$)", stem):
            return expansion, "Cinematics & Story", "filename-category"
        return expansion, "Other Zone Music", "unmapped-location"
    if folder == "citymusic" and len(bits)>3:
        names={"darnassus":"Darnassus","ironforge":"Ironforge","orgrimmar":"Orgrimmar",
               "stormwind":"Stormwind","thunderbluff":"Thunder Bluff","undercity":"Undercity"}
        return EXPANSIONS[0], names.get(bits[3], "Cities & Shared Themes"), "legacy-folder"
    if folder == "zonemusic" and len(bits)>3:
        zone=bits[3]
        if zone in BC_ZONES:return EXPANSIONS[1],BC_ZONES[zone],"legacy-folder"
        if zone in WRATH_ZONES:return EXPANSIONS[2],WRATH_ZONES[zone],"legacy-folder"
        if zone in LEGACY_ZONES:return EXPANSIONS[0],LEGACY_ZONES[zone],"legacy-folder"
        if zone == "wanderingisle":return EXPANSIONS[4],"The Wandering Isle","legacy-folder"
        if zone == "darkmoonfaire":return EXPANSIONS[3],"Darkmoon Faire","legacy-folder"
    if folder == "gluescreenmusic":
        expansion=EXPANSIONS[1] if stem.startswith("bc") else EXPANSIONS[2] if stem.startswith("wotlk") else EXPANSIONS[0]
        return expansion,"Login Screen & Credits","legacy-filename"
    if folder == "musical moments":return EXPANSIONS[0],"Musical Moments","legacy-folder"
    if folder == "worldevents":return EXPANSIONS[0],"World Events","legacy-folder"
    if folder == "petbattles":return EXPANSIONS[4],"Pet Battles","feature-era"
    if folder == "event":
        if "715_" in stem or "725_" in stem or "diabloanniversary" in stem:return EXPANSIONS[6],"Special Events","filename-era"
        if stem.startswith(("gnomeregan", "zf")):return EXPANSIONS[2],"Pre-Cataclysm Events","event-era"
    return None

def title_for(path, vocabulary):
    stem = Path(path).stem
    stem = re.sub(r"^(?:mus|music)[_ ]*", "", stem, flags=re.I)
    stem = re.sub(r"^\d{2,4}_", "", stem)
    stem = re.sub(r"^(aw|ba|mx|rd)_", "", stem, flags=re.I)
    stem = re.sub(r"^[A-Z]{1,3}_", "", stem)
    suffix = ""
    legacy = re.search(r"_?(?:([gu][und])|uni)(\d+)$",stem,re.I)
    m = re.search(r"(?:_|\b)(v?\d+[a-z]?|[a-z]\d*)$", stem, re.I)
    if legacy:
        mode=(legacy[1] or "uu")[-1].lower()
        context={"d":"Day, ","n":"Night, "}.get(mode,"")
        suffix=" ("+context+"Variation "+str(int(legacy[2]))+")"
        stem=stem[:legacy.start()]
    elif m:
        variant=m[1];stem=stem[:m.start()]
        variant=re.sub(r"^v(?=\d)","",variant,flags=re.I)
        if variant.isdigit():variant=str(int(variant))
        suffix=" (Variation " + variant.upper() + ")"
    label = friendly(stem, vocabulary)
    label = re.sub(r"\bIntro\b", "Introduction", label)
    label = re.sub(r"\bWalk\b", "Walking", label)
    label = re.sub(r"\bPt\s*(\d+)", r"Part \1", label)
    label = re.sub(r"\bUni\b", "Universal", label)
    return (label or "Music") + suffix

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    args=parser.parse_args()
    source=json.loads((ROOT/"tools/catalog-source.json").read_text())
    payload=args.source.read_bytes()
    if hashlib.sha256(payload).hexdigest()!=source["sha256"]:
        raise SystemExit("Source SHA256 differs from the pinned manifest. Review/update the manifest before rebuilding.")
    overrides=json.loads((ROOT/"tools/catalog-overrides.json").read_text())
    zone_metadata=json.loads((ROOT/"tools/zone-music-file-ids.json").read_text())
    zone_files=zone_metadata["files"]
    music=[]
    for line in payload.decode("utf-8-sig").splitlines():
        fields=line.split(";",1)
        if len(fields)==2 and fields[0].isdigit() and fields[1].replace("\\","/").lower().startswith("sound/music/"):
            music.append((int(fields[0]),fields[1].replace("\\","/")))
    names=[p for _,p in music]
    for file in zone_files.values():
        names.append(file.get("title",""))
        names.extend(file.get("soundKitNames",[]))
    vocabulary=make_vocabulary(names);included={};excluded=[]
    for fdid,path in music:
        reason=None
        if str(fdid) not in overrides:
            if Path(path).suffix.lower() not in (".mp3",".ogg"):reason="metadata-not-audio"
            elif path.lower().split("/")[2] in ("classic","forever"):reason="outside-requested-expansion-folders"
            elif re.search(r"(?:^|[_/])(notused|unused|soundtest|test|beta|placeholder|debug)(?:[_/.]|$)",path,re.I):reason="explicit-test-beta-or-unused-name"
            elif path.lower().split("/")[2] not in set(FOLDERS)|{"citymusic","zonemusic"}:reason="not-zone-background-music"
            elif re.search(r"(?:^|[_/])(rtc|scene|cinematic|cinematics|dialogue|dialog|voice|vo|sfx|credits|maintitle|main_title|login|trailer|stinger|sting|jingle|fanfare)(?:[_/.]|$)",path,re.I):reason="scene-voice-effect-or-nonbackground-cue"
            elif str(fdid) not in zone_files:reason="zone-music-category-not-established"
        mapping=classify(path)
        if not reason and not mapping and str(fdid) not in overrides:reason="expansion-not-established"
        if reason:
            excluded.append({"fileDataID":fdid,"sourceFilename":path,"reason":reason});continue
        if str(fdid) in overrides:
            row=dict(overrides[str(fdid)]);row["mappingSource"]="prototype-override"
        else:
            expansion,zone,method=mapping
            row={"key":f"music-{fdid}","title":title_for(path,vocabulary),"zone":zone,"expansion":expansion,
                 "fileDataID":fdid,"sourceFilename":path,"playbackVerified":False,"mappingSource":method}
        row["soundKitIDs"]=";".join(str(x) for x in zone_files.get(str(fdid),{}).get("soundKitIDs",[]))
        if fdid in included:raise SystemExit(f"Duplicate FileDataID: {fdid}")
        included[fdid]=row
    for fdid,override in overrides.items():
        if int(fdid) not in included:raise SystemExit(f"Preserved entry missing from source: {fdid}")
    # Distinct files with identical cleaned names remain individually selectable.
    duplicates=Counter((r["expansion"],r["zone"],r["title"].lower()) for r in included.values())
    seen=Counter()
    for row in sorted(included.values(), key=lambda r:(r["mappingSource"]!="prototype-override",r["fileDataID"])):
        ident=(row["expansion"],row["zone"],row["title"].lower());seen[ident]+=1
        if duplicates[ident]>1 and seen[ident]>1:row["title"]+=f" (Alternate {seen[ident]})"
    rows=sorted(included.values(),key=lambda r:(EXPANSIONS.index(r["expansion"]),r["zone"].lower(),r["title"].lower(),r["fileDataID"]))
    lines=["-- MusicSCAN v0.7.1 BETA | SCAN | Kilobytes Development", "-- Generated by tools/build_catalog.py; metadata only, no audio or runtime downloads.",
           "-- Filename associations are provisional; see SOURCES.md for provenance.", "local _, ns = ...", "", "ns.ExpansionOrder = {"]
    for i,name in enumerate(EXPANSIONS,1):lines.append(f"    [{json.dumps(name)}] = {i},")
    lines.extend(["}","", "ns.Catalog = {"])
    for row in rows:
        fields=[]
        for key in ("key","title","zone","expansion","fileDataID","sourceFilename","playbackVerified","mappingSource"):
            fields.append(key+"="+json.dumps(row[key],ensure_ascii=True))
        lines.append("    {"+", ".join(fields)+"},")
    lines.extend(["}","",'ns.DEFAULT_TRACK_KEY = "wod-frostfire-magnificent-desolation-h"',""])
    (ROOT/"MusicSCAN/Database.lua").write_text("\n".join(lines))
    columns=["fileDataID","key","expansion","zone","title","playbackVerified","mappingSource","sourceFilename","soundKitIDs"]
    with (ROOT/"catalog/CATALOG.csv").open("w",newline="") as f:
        writer=csv.DictWriter(f,fieldnames=columns);writer.writeheader();writer.writerows(rows)
    with (ROOT/"tools/catalog-exclusions.csv").open("w",newline="") as f:
        writer=csv.DictWriter(f,fieldnames=["fileDataID","reason","sourceFilename"]);writer.writeheader();writer.writerows(excluded)
    summary={**source,"totalMusicPaths":len(music),"includedAudioFiles":len(rows),
             "confirmedPlayback":sum(r["playbackVerified"] for r in rows),
             "byExpansion":{e:sum(r["expansion"]==e for r in rows) for e in EXPANSIONS},
             "byMapping":dict(Counter(r["mappingSource"] for r in rows)),
             "zoneMusicLookup":{"source":zone_metadata["source"],"soundType":zone_metadata["soundType"],
                                "fileIDs":len(zone_files),"soundKits":zone_metadata["soundKits"]},
             "excludedByReason":dict(Counter(r["reason"] for r in excluded))}
    assert len(rows)+len(excluded)==len(music)
    (ROOT/"catalog/CATALOG-SOURCE.json").write_text(json.dumps(summary,indent=2)+"\n")
    print(json.dumps(summary,indent=2))

if __name__=="__main__":main()
