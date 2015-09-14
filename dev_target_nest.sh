function nestBuild() { _dargonBuildAll "Dargon Nest" _nestBuild; }
function nestListProcesses() { WMIC PROCESS get ProcessId,CommandLine /format:csv | grep nest | cut -d ',' -f 2-; }

function _nestBuildCli()         { _dargonBuildEgg "nest"               "Dargon.Nest/nest"               "nest.csproj"; }
function _nestBuildDaemon()      { _dargonBuildEgg "nestd"              "Dargon.Nest/nestd"              "nestd.csproj"; }
function _nestBuildHost()        { _dargonBuildEgg "nest-host"          "Dargon.Nest/nest-host"          "nest-host.csproj"; }
function _nestBuildExampleEgg()  { _dargonBuildEgg "dev-egg-example"    "Dargon.Nest/dev-egg-example"    "dev-egg-example.csproj"; }
function _nestBuildCommander()   { _dargonBuildEgg "dev-nest-commander" "Dargon.Nest/dev-nest-commander" "dev-nest-commander.csproj"; }

function _nestStartSpawner()     { ("$NEST_DIR/nest-spawner/nest-spawner.exe"); }
function _nestStartDaemon()      { shellExecute "$(toWindowsPath $NEST_DIR/nestd/nestd.exe)" $@; }
function _nestStartEgg()         { "$NEST_DIR/dev-nest-commander/dev-nest-commander.exe" -c spawn-egg $@; }
function _nestKill()             { "$NEST_DIR/dev-nest-commander/dev-nest-commander.exe" -c kill-nest $@; }
function _nestStartCli()         { cd $NEST_DIR && "$NEST_DIR/nest/nest.exe"; }