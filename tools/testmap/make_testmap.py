"""Prepare the IW7D cp_testmap zone source from a ZoneTool dump of cp_town.

Usage:
    python -I make_testmap.py <dump dir of cp_town> <game dir> [<dump dir of patch_cp_town>]

What it builds (all inside <game dir>):
    zonetool/cp_testmap/   the renamed world assets, the level script and the map-specific rawfiles
    zone_source/           cp_testmap.csv (the zone) and cp_testmap_base.csv (everything that stays
                           a reference to the stock cp_town zone, which the client loads first)
    usermaps/cp_testmap/   arena, base and desc files; the built cp_testmap.ff is moved here afterwards

Then run, from the game dir:  zonetool.exe -buildzone cp_testmap
"""

import shutil
import sys
from pathlib import Path

SRC = "cp_town"
DST = "cp_testmap"

WORLD_TYPES = ["com_map", "navmesh", "fx_map", "gfx_map", "map_ents", "glass_map", "aipaths", "col_map"]

# Props placed along the street between the two groups of default_player_start structs.
# Keys are IW7 entity token ids: 157 classname, 822 targetname, 497 model, 543 origin, 65 angles.
PROPS = [
    ("cp_town_teleporter_device", "3810 -4180 16", "0 150 0"),
    ("cp_town_mind_control_device", "3740 -3990 16", "0 150 0"),
    ("cp_town_seismic_wave_device", "3690 -3800 16", "0 150 0"),
    ("cp_town_hypnosis_device", "3640 -3610 16", "0 150 0"),
    ("cp_town_violet_xray_device", "3590 -3420 16", "0 150 0"),
]

LEVEL_SCRIPT = r"""// IW7D cp_testmap: the cp_town world under a new name, with a few extra props.
// Built by tools/testmap/make_testmap.py and baked into cp_testmap.ff as a rawfile.

main()
{
    level.iw7d_custom_map = 1;
    level thread iw7d_props();

    scripts\cp\maps\cp_town\cp_town::main();
}

iw7d_props()
{
    props = getentarray( "iw7d_prop", "targetname" );
    foreach ( prop in props )
        prop thread iw7d_spin();

    wait 8;
    iprintlnbold( "IW7D CUSTOM MAP: cp_testmap" );
}

iw7d_spin()
{
    self endon( "death" );

    for ( ;; )
    {
        self rotateyaw( 360, 12 );
        wait 12;
    }
}
"""

ARENA = """{
\tmap\t\t\t"cp_testmap"
\tlongname\t"IW7D TEST MAP"
\tgametype\t"zombie Aliens escape"
\tdefaultgametype "zombie"
\tdescription "IW7D test map built with ZoneTool: the cp_town world under a new name, with extra props."
\tmapimage    "zm_theater_poster_town"
\tmappack\t\t"0"
}
"""

DESC = "IW7D test map built with ZoneTool. The cp_town world under a new name, with a row of extra props near spawn."


def patched_copy(src: Path, dst: Path, replacements):
    data = src.read_bytes()
    for old, new, expected in replacements:
        found = data.count(old)
        if expected is not None and found != expected:
            raise SystemExit(f"{src}: expected {expected} x {old!r}, found {found}")
        data = data.replace(old, new)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(data)
    return data


def write(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def main():
    dump = Path(sys.argv[1])
    game = Path(sys.argv[2])
    out = game / "zonetool" / DST
    zone_source = game / "zone_source"
    usermap = game / "usermaps" / DST

    full_old = f"maps/cp/{SRC}.d3dbsp".encode()
    full_new = f"maps/cp/{DST}.d3dbsp".encode()

    # world assets: same files, renamed, with the asset name patched inside the binaries
    prefix = f"{SRC}.d3dbsp"
    for f in sorted((dump / "maps" / "cp").iterdir()):
        if not f.name.startswith(prefix):
            continue
        suffix = f.name[len(prefix):]
        dst = out / "maps" / "cp" / f"{DST}.d3dbsp{suffix}"
        data = patched_copy(f, dst, [(full_old, full_new, None)])
        if suffix == ".ents":
            # the dump ends with a NUL terminator, which has to stay last
            ents = data.decode("latin-1").rstrip("\0")
            if not ents.endswith("\n"):
                ents += "\n"
            for model, origin, angles in PROPS:
                ents += "{\n"
                ents += f'157 "script_model"\n822 "iw7d_prop"\n497 "{model}"\n543 "{origin}"\n65 "{angles}"\n'
                ents += "}\n"
            dst.write_bytes(ents.encode("latin-1") + b"\0")
        print(f"world  {dst.relative_to(game)}")

    extra_assets = []

    # streaming info is looked up by map name; its name is the first string of the dump
    streaming = dump / "streaming_info" / SRC
    if streaming.is_file():
        data = streaming.read_bytes()
        old = b"\x06\x01" + SRC.encode() + b"\x00"
        if data.count(old) == 1:
            patched_copy(streaming, out / "streaming_info" / DST, [(old, b"\x06\x01" + DST.encode() + b"\x00", 1)])
            extra_assets.append(f"streaminginfo,{DST}")
            print("streaming info renamed")
        else:
            print(f"streaming info skipped: found {data.count(old)} name strings")

    impact = dump / "impactfx" / f"{SRC}.json"
    if impact.is_file():
        dst = out / "impactfx" / f"{DST}.json"
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(impact, dst)
        extra_assets.append(f"impactfx,{DST}")

    baseline = dump / "cp" / "constbaselines" / f"bl_pc_{SRC}_zombie.bin"
    if baseline.is_file():
        dst = out / "cp" / "constbaselines" / f"bl_pc_{DST}_zombie.bin"
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(baseline, dst)
        extra_assets.append(f"rawfile,cp/constbaselines/bl_pc_{DST}_zombie.bin")

    # The zombie scripts build some table and file names from the map name. Those live in the
    # map's patch zone and other companion zones, so every extra dump dir given on the command
    # line is scanned for map-named stringtables and rawfiles, copied under the new name
    # (compiled .gsc rawfiles are referenced by their literal path and are skipped).
    # A dir without a zone listing is a flat table dump (the client's stringTableDump output):
    # every file in it is a stringtable named by its relative path.
    seen_extra = set()
    for extra in (Path(p) for p in sys.argv[3:]):
        csv = extra / f"{extra.name}.csv"
        if csv.is_file():
            entries = [line.strip().split(",") for line in csv.read_text(encoding="utf-8", errors="replace").splitlines()]
        else:
            entries = [["stringtable", f.relative_to(extra).as_posix()] for f in extra.rglob("*") if f.is_file()]
        for parts in entries:
            if len(parts) != 2 or parts[0] not in ("stringtable", "rawfile") or SRC not in parts[1]:
                continue
            if parts[1].endswith(".gsc") or parts[1] in seen_extra:
                continue
            src_file = extra / parts[1]
            if not src_file.is_file():
                print(f"asset missing on disk, skipped: {parts[1]}")
                continue
            seen_extra.add(parts[1])
            new_name = parts[1].replace(SRC, DST)
            dst = out / new_name
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src_file, dst)
            extra_assets.append(f"{parts[0]},{new_name}")
            print(f"{extra.name:18s} {parts[0]} {new_name}")

    script_path = f"scripts/cp/maps/{DST}/{DST}.gsc"
    write(out / script_path, LEVEL_SCRIPT)
    extra_assets.append(f"rawfile,{script_path}")

    # zone csv: the world under the new name, everything else referenced from the base zone
    lines = [
        f"// IW7D {DST}: the {SRC} world under a new name.",
        f"// Every other asset is a reference, resolved from the stock {SRC} zone that the",
        f"// client loads first (usermaps/{DST}/{DST}.base).",
        f"ignore,{DST}_base",
    ]
    lines += extra_assets
    lines += [f"{t},maps/cp/{DST}.d3dbsp" for t in WORLD_TYPES]
    write(zone_source / f"{DST}.csv", "\n".join(lines) + "\n")

    # ignore list: every asset of the stock zone, with reference lines (type,,name) flattened
    base_lines = []
    for line in (dump / f"{SRC}.csv").read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line or line.startswith("//") or line.startswith("#"):
            continue
        parts = line.split(",")
        if len(parts) >= 3 and parts[1] == "":
            parts = [parts[0], parts[2]]
        base_lines.append(",".join(parts[:2]))
    write(zone_source / f"{DST}_base.csv", "\n".join(base_lines) + "\n")
    print(f"ignore list: {len(base_lines)} assets")

    write(usermap / f"{DST}.arena", ARENA)
    write(usermap / f"{DST}.base", f"{SRC}\n")
    write(usermap / "desc.txt", DESC)
    print("done")


if __name__ == "__main__":
    main()
