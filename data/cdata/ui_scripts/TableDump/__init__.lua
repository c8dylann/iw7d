-- IW7D dev helper: when a match is started with iw7d_dumptables set to 1, dumps every loaded
-- string table and localize entry to iw7-mod/dump/ about 40 seconds after the in-game UI comes
-- up. Used to find the map-named tables a usermap clone has to provide (see tools/testmap).
-- Inert otherwise. The dvar is only cleared once the dump has run, so the loading-screen and
-- the in-game UI instance both schedule it and the later one wins.
if Engine.InFrontend() then
    return
end

if Engine.GetDvarString("iw7d_dumptables") ~= "1" then
    return
end

scheduler.once(function()
    Engine.SetDvarString("iw7d_dumptables", "0")
    Engine.Exec("stringTableDump")
    Engine.Exec("localizeDump")
    print("[iw7d] string tables and localize entries dumped")
end, 40000)
