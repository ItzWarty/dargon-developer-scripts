function nestBuild() { _dargonBuildAll "Dargon Nest" _nestBuild; }
function nestListProcesses() { WMIC PROCESS get ProcessId,CommandLine /format:csv | grep nest | cut -d ',' -f 2-; }

function _nestBuildNestCli()         { _dargonBuildEgg "nest"              "Dargon.Nest/nest"               "nest.csproj"; }
function _nestBuildNestDaemon()      { _dargonBuildEgg "nestd"             "Dargon.Nest/nestd"              "nestd.csproj"; }
function _nestBuildNestHost()        { _dargonBuildEgg "nest-host"         "Dargon.Nest/nest-host"          "nest-host.csproj"; }
function _nestBuildNestExampleEgg()  { _dargonBuildEgg "dev-egg-example"   "Dargon.Nest/dev-egg-example"    "dev-egg-example.csproj"; }
function _nestBuildNestRunnerEgg()   { _dargonBuildEgg "dev-egg-runner"    "Dargon.Nest/dev-egg-runner"     "dev-egg-runner.csproj"; }

function _nestStartSpawner()     { ("$NEST_DIR/nest-spawner/nest-spawner.exe"); }
function _nestStartDaemon()      { shellExecute "$(toWindowsPath $NEST_DIR/nestd/nestd.exe)" $@; }
function _nestStartEgg()         { ("$NEST_DIR/dev-egg-runner/dev-egg-runner.exe" $@ &); }
function _nestStartCli()         { cd $NEST_DIR && "$NEST_DIR/nest/nest.exe"; }