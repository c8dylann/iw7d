# Der Riese in IW7D: port plan

Written 2026-10-29. Facts below were checked on that date; mod projects move fast, so re-check the
links before buying anything.

## Where it stands

- Der Riese is a World at War map (`nazi_zombie_factory`), remade in Black Ops 1 and as *The Giant*
  (`zm_factory`) in Black Ops 3. It is not an MWR map.
- Nothing on this PC contains it: no WaW, no BO1, no MWR, and the installed BO3 has Nacht
  (`zm_prototype`), Shadows of Evil, Der Eisendrache and the Chronicles maps but not The Giant. The
  BO3 mod tools only ship the `zm_test`/`zm_wane` example sources.
- No finished IW7 port of Der Riese was found publicly.
- The only Der Riese usermap in the ZoneTool ecosystem is for **IW5 (Modern Warfare 3)**: a port
  from CoD Online released on the Plutonium forum
  (<https://forum.plutonium.pw/topic/33031/map-release-der-riese-from-cod-ol/9>). No MWR (H1) port
  was found.
- Black Ops 3 cannot be a source for geometry: x64-zt's T7 converter only handles models and
  animations.

## What you would need

| Need | Why | Where |
|---|---|---|
| Modern Warfare 3 (IW5) game files | The Der Riese usermap is an IW5 map; the old zonetool runs on `iw5mp.exe` | Steam; Plutonium (free) runs on top of it to test the map |
| The Der Riese IW5 usermap | The geometry | Plutonium forum thread above |
| Modern Warfare Remastered (H1), **route B only** | x64-zt's mature world converter is H1 to IW7 and runs on `h1_mp64_ship.exe` | Steam |
| [Joelrau/zonetool](https://github.com/Joelrau/zonetool) (the DLL, x64 branch) | Dumps IW3/IW4/IW5 maps with a target game | GitHub releases |
| [x64-zt](https://github.com/Joelrau/x64-zt) | Builds H1 and IW7 zones; already built at `Downloads\x64-zt` with this fork's `gfx_world_tr` reference fix | local |

## Route A: IW5 straight to IW7 (fewer games, less proven)

The old zonetool's README lists IW7 as a `dumpzone` target. If that target is complete enough, MWR is
not needed.

1. Install the Der Riese usermap for IW5 and confirm it runs in Plutonium.
2. In the MW3 folder, with `zonetool_iw5.exe` and `zonetool.dll` next to the game:
   `dumpzone mp_der_riese iw7` (the exact map name comes from the usermap's `.ff`).
3. Move `dump\mp_der_riese\` to the IW folder as `zonetool\cp_der_riese\` and continue at
   "IW7 side" below.

If the dump is missing techsets/materials for IW7 (the usual failure), fall back to route B.

## Route B: IW5 to H1 to IW7 (the documented chain)

Aurora documents IW3/IW4/IW5 to H1 at <https://docs.auroramod.dev/map-porting-iw5> and next-gen to
next-gen at <https://docs.auroramod.dev/map-porting-s1>.

1. IW5 to H1: in the MW3 folder, `dumpzone mp_der_riese h1`. Move the dump to
   `%MWR%\zonetool\mp_der_riese\`. In x64-zt (run from the MWR folder): `generatecsv mp_der_riese`,
   then `buildzone mp_der_riese`. Fix missing techsets by dumping `common_mp` for H1 into a
   `zonetool_paths` folder, as the guide describes. Test it in H1-Mod so the H1 version is known
   good before going further.
2. H1 to IW7: in the MWR folder, `dumpmap iw7 mp_der_riese _ true` (`_` = no asset filter,
   `true` = skip common zones). The converter covers gfxworld, clipmap, comworld, fxworld,
   glassworld, aipaths, materials, techsets, images, xmodels and xsurfaces. Move the dump to
   `%IW%\zonetool\cp_der_riese\`.

## IW7 side (both routes)

1. **Name.** Zombies maps must start with `cp_`: the client picks the game mode from the prefix and
   files `cp_` usermaps under zombies. Rename every `maps/mp/mp_der_riese.d3dbsp*` file to
   `maps/cp/cp_der_riese.d3dbsp*` and patch the name string inside the binaries the same way
   `tools/testmap/make_testmap.py` does for `cp_testmap`.
2. **Entities.** IW7 entity files use numeric token keys (`157 "script_model"`, `543` origin, `65`
   angles, `497` model, `822` targetname); IW5/H1 files use names. Convert keys with the IW7 gsc-tool
   token table (the same one the client's compiler uses). This needs a small script; nothing in
   x64-zt does it for you.
3. **Zone csv.** `generatecsv cp_der_riese` in the IW folder gives a starting csv. Add
   `ignore,<base>_assets` with a stock zombie map's listing so weapons, zombies, perks and HUD assets
   stay references, and put that map in `usermaps/cp_der_riese/cp_der_riese.base` (for example
   `cp_zmb`). The client loads it before the map zone; the engine adds its `eng_`/`patch_` zones.
   Do not list those explicitly: it hangs the game.
4. **Map-named tables.** The zombie scripts look up `cp/zombies/<map>_loot.csv`,
   `cp/zombies/<map>_playercash_images.csv`, `cp/<map>_wall_buy_models.csv`, `cp/<map>_vo_table.csv`,
   `cp/<map>_weapontable.csv`, `cp/zombies/<map>_music_ee.csv`, `cp/zombies/<map>_music_genre.csv`,
   `cp/zombies/<map>_challenges.csv`, `scripts/cp/maps/<map>/<map>_crafting.csv` and
   `scripts/cp/maps/<map>/<map>_weaponrank_event.csv` by map name. Copy them from the base map under
   the new name; `make_testmap.py` already does this given a `patch_<map>` dump and a
   `stringTableDump` of a stock match.
5. **Level script.** `scripts/cp/maps/cp_der_riese/cp_der_riese.gsc` as a rawfile in the zone. For
   a first load it can be a near-empty `main()`. For zombies it has to do what a stock map script
   does: run `gscDump` in a stock match (dev command, available in every IW7D build) to get the
   decompiled `cp_zmb` scripts as the reference. Keep decompiled stock scripts local; do not commit
   them.
6. **Entities the zombies gametype expects**, taken from `cp_town`: `default_player_start`
   structs, `player_respawn_loc`, zombie spawn structs (`*_spawn`, `*_spawner`, `ghost_spawn`),
   `info_volume` zones, `trigger_use` doors and wall buys, mystery box and perk structs, a power
   switch, `trigger_hurt`, `mp_global_intermission`. All of these are placed by hand in the
   converted `.ents`, plus the script that drives them.
7. **Arena.** `usermaps/cp_der_riese/cp_der_riese.arena` with `gametype "zombie Aliens escape"` and
   `defaultgametype "zombie"`, like `cp_testmap`.
8. `zonetool.exe -buildzone cp_der_riese`, move the `.ff` into `usermaps/cp_der_riese/`, launch
   with `iw7d.exe -nointro +map cp_der_riese`, and read `iw7-mod/logs/console.log`. Real errors show
   as an in-game popup, not in the log.

## The hard part: AI pathing

Stock zombie maps ship a `navmesh` asset for the map's geometry, and the zombies (agents) path on
it. A ported map has none, and x64-zt cannot generate one. Without it the map loads and you can walk
around, but zombies will not move. Options, none of them small:

- Research the IW7 navmesh format (x64-zt's `iw7/assets/navmesh.cpp` reads and writes it) and build a
  generator from the clipmap, probably with Recast.
- Find someone in the IW7 modding community who has solved it; the custom survival map seen on
  YouTube implies at least one person has working zombies on a custom map.

## Milestones and honest effort

1. **Geometry loads** (`cp_der_riese` free-roam, no zombies): a few evenings once MW3 (and MWR for
   route B) plus the usermap are in hand. Expect several build/test cycles for materials.
2. **Zombies gametype runs**: entities, tables, level script. Weeks of work; most of it is scripting
   against decompiled stock scripts.
3. **Zombies move**: blocked on a navmesh generator. Open-ended.

What exists today in this fork, the stock-map clone pipeline (`tools/testmap`), the `.base`
feature, the dump commands and the Custom Maps menu, is the part all three milestones sit on.
