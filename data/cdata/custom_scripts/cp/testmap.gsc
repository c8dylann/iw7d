// IW7D test map: a small prop playground placed in front of the first player's spawn.
// It only runs for a match started from the TEST MAP entry of the Custom Maps menu, which
// sets iw7d_testmap to 1 before starting cp_town. The dvar is cleared again straight away so
// the next match is a normal one.

init()
{
    if ( getdvarint( "iw7d_testmap", 0 ) != 1 )
        return;

    setdvar( "iw7d_testmap", 0 );

    level.iw7d_testmap_models = [
        "cp_town_teleporter_device",
        "cp_town_mind_control_device",
        "cp_town_seismic_wave_device",
        "cp_town_hypnosis_device",
        "cp_town_violet_xray_device",
        "cp_town_radiation_extractor"
    ];

    // models have to be precached while the level is still loading
    foreach ( model in level.iw7d_testmap_models )
        precachemodel( model );

    println( "[iw7d] test map enabled" );
    level thread testmap_wait_for_player();
}

testmap_wait_for_player()
{
    level waittill( "connected", player );
    player thread testmap_on_spawn();
}

testmap_on_spawn()
{
    self endon( "disconnect" );

    scripts\engine\utility::waittill_any( "spawned_player", "faux_spawn" );
    wait 3;

    level thread testmap_build( self.origin, self.angles );
}

testmap_build( origin, angles )
{
    forward = anglestoforward( angles );
    right = anglestoright( angles );
    center = origin + forward * 220;
    count = level.iw7d_testmap_models.size;

    for ( i = 0; i < count; i++ )
    {
        offset = ( i - ( count - 1 ) * 0.5 ) * 90;

        prop = spawn( "script_model", center + right * offset );
        prop setmodel( level.iw7d_testmap_models[i] );
        prop.angles = ( 0, angles[1] + 180, 0 );
        prop thread testmap_spin();

        println( "[iw7d] spawned " + level.iw7d_testmap_models[i] );
    }

    iprintlnbold( "IW7D TEST MAP" );
}

testmap_spin()
{
    for ( ;; )
    {
        self rotateyaw( 360, 10 );
        wait 10;
    }
}
