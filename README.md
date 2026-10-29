![license](https://img.shields.io/github/license/h1-mod/iw7-mod.svg)
[![open bugs](https://img.shields.io/github/issues/h1-mod/iw7-mod/bug?label=bugs)](https://github.com/h1-mod/iw7-mod/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![discord](https://img.shields.io/discord/945420505157083208?color=%237289DA&label=members&logo=discord&logoColor=%23FFFFFF)](https://discord.gg/RzzXu5EVnh)
<!--
[![Build](https://github.com/h1-mod/h1-mod/workflows/Build/badge.svg)](https://github.com/h1-mod/h1-mod/actions)
[![Build status](https://ci.appveyor.com/api/projects/status/0sh80kdnsvm53rno?svg=true)](https://ci.appveyor.com/project/h1-mod/h1-mod)
-->

# IW7-Mod

IW7-Mod is a client for Call of Duty®: Infinite Warfare that adds dedicated servers, hands-on modding utilities, and custom mods that feature content like weapons, models, sounds, and more. ***You must legally own [Call of Duty®: Infinite Warfare](https://store.steampowered.com/app/292730/Call_of_Duty_Infinite_Warfare/)*** to run this mod. Unlicensed or cracked versions of the game are **NOT** supported and will not be given assistance.

<p align="center">
  <img src="assets/github/banner.png?raw=true" width="500" height="500" />
</p>

## IW7D changes

IW7D is a fork of [IW7-Mod](https://github.com/auroramod/iw7-mod). On top of upstream it adds:

- **Custom Maps menu** - a `CUSTOM MAPS` button on the lobby screen and in the lobby's Game Setup screen, under `MAPS`. In the zombies lobby it is a clickable `CUSTOM MAPS` entry in the bottom button bar (also bound to the `button_alt2` key). The menu lists every map installed in `usermaps/<name>/<name>.ff` for the current mode, plus a `TEST MAP` entry for zombies. `TEST MAP` is only an alias: it starts the stock `cp_town` map, with a small showroom of rotating props placed in front of your spawn by `custom_scripts/cp/testmap.gsc`, until a real map is installed in `usermaps/cp_testmap/`. Selecting a map starts it with the `map` command. Add an optional `usermaps/<name>/desc.txt` for the description shown next to the list.
- **IW7D branding** in the in-game text, console and window titles.
- **The updater is opt-in.** The official update server only serves stock IW7-Mod and would overwrite the IW7D scripts, so nothing is downloaded unless you start the game with `-update`.

Because the updater is off, copy the contents of `data\cdata` into `%LOCALAPPDATA%\auroramod\iw7-mod\cdata` after pulling changes (this is what the updater normally does).

### Custom maps

IW7 has no map editor, so a custom map is built from dumped stock assets with [x64 ZoneTool](https://github.com/Joelrau/x64-zt) (its `gfx_world_tr::init` needs the reference fix from this fork's history to build maps in reference mode). `tools/testmap/make_testmap.py` builds `cp_testmap`, the `cp_town` world under a new name with extra props, and documents the whole pipeline:

1. `zonetool.exe -dumpzone cp_town` and `-dumpzone patch_cp_town` in the game folder.
2. Run the game once with `+set iw7d_dumptables 1 +map cp_town` and, from the `-syscon` console, `stringTableDump` to get every table a running match loads (the zombie scripts look up `<map>_loot.csv`, `<map>_playercash_images.csv` and others by map name).
3. `make_testmap.py <cp_town dump> <game dir> <patch_cp_town dump> <table dump>` writes `zonetool/cp_testmap`, `zone_source/cp_testmap.csv` and `usermaps/cp_testmap/`.
4. `zonetool.exe -buildzone cp_testmap`, then move `cp_testmap.ff` into `usermaps/cp_testmap/`.

The built zone only carries the renamed world assets (gfx/col/com/fx/glass map, entities, navmesh, AI paths), the map-named tables and the level script; everything else is a reference. `usermaps/<map>/<map>.base` lists the stock zones the client loads right before the map zone so those references resolve. The engine loads a zone's `eng_` and `patch_` companions by itself, so only `cp_town` goes in that file.

Dev commands `gscDump`, `luaDump`, `stringTableDump`, `localizeDump`, `commandDump` and `entityDump` are available in every build (upstream has them in debug builds only); they write to `iw7-mod/dump/`.

## Download

To download IW7-Mod, [read our Installing IW7-Mod guide](https://docs.auroramod.dev/iw7-install) to help you.

## Compile from source code

- Clone the Git repo via [Git](https://git-scm.com/install/windows) or [GitHub Desktop](https://desktop.github.com/download/). **DO NOT download it as ZIP** as it will not work.
- Run the `generate.bat` script to generate the project solution.
- Build the project via the generated solution file in `build\iw7-mod.sln`.

## Credits

- [s1x-client](https://git.alterware.dev/alterware/s1-mod) *(now **s1-mod**)* - codebase and research
- [h1-mod](https://github.com/auroramod/h1-mod) - extended work and research
- [h2-mod](https://github.com/alicelys/h2-mod) - research
- [momo5502](https://github.com/momo5502) - Arxan & Steam research, former lead developer of [XLabsProject](https://github.com/XLabsProject)

## Disclaimer

This software has been created purely for the purposes of academic research. It is not intended to be used to attack other systems. Project maintainers are not responsible or liable for misuse of the software. Use responsibly.
