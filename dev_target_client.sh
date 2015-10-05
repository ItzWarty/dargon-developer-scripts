CLIENT_NEST_PORT=21999;
CLIENT_NESTD_MANAGEMENT_PORT=21000;

function pushdCore()    { pushd "$DARGON_REPOSITORIES_DIR/the-dargon-project"; }

function clientBuild()           { _clientTryKill; _dargonBuildAll "Dargon Client" "client"; }
function clientStartHeadless()   { _clientTryKill; _dargonStart _clientStartNestD _clientStartCoreD; }
function clientStartWithGui()    { _clientTryKill; _dargonStart clientStartHeadless _clientStartManager; }
function clientStartWithCli()    { _clientTryKill; _dargonStart clientStartHeadless _clientStartCli; }
function clientKill()            { _nestKill -p $CLIENT_NEST_PORT; }

function _clientTryKill()        { _nestTryKill -p $CLIENT_NEST_PORT $@; }
function _clientStartNestD()     { _nestStartDaemon -p $CLIENT_NEST_PORT -m $CLIENT_NESTD_MANAGEMENT_PORT $@; }
function _clientStartEgg()       { _nestStartEgg -p $CLIENT_NEST_PORT -e $1 ; }
function _clientStartCoreD()     { _clientStartEgg "cored"; }
function _clientStartManager()   { _clientStartEgg "dargon-client"; }
function _clientStartThumbGen()  { _clientStartEgg "thumbnail-generator"; }
function _clientStartCli()       { eval "$NEST_DIR/dargon-cli/dargon-cli.exe"; }

function _clientPrebuild() { _dargonSetupDevelopmentNest "client"; }
function _clientBuildCoreDaemon()            { _dargonBuildEgg "client"     "cored"                 "the-dargon-project/daemon-impl"             "daemon-impl.csproj"; }
function _clientBuildClient()                { _dargonBuildEgg "client"     "dargon-client"         "the-dargon-project/dargon-client"           "dargon-client.csproj"; }
function _clientBuildCli()                   { _dargonBuildEgg "client"     "dargon-cli"            "the-dargon-project/dargon-cli"              "dargon-cli.csproj"; }
function _clientBuildTrinket()               { _dargonBuildEgg "client"     "trinket"               "the-dargon-project/trinket-proxy-impl"      "trinket-proxy-impl.csproj"; }
function _clientBuildTrinketDim()            { _dargonBuildEgg "client"     "trinket-dim"           "the-dargon-project/DargonInjectedModule"    "Dargon - Injected Module.vcxproj"; }
function _clientBuildThumbnailGenerator()    { _dargonBuildEgg "client"     "thumbnail-generator"   "the-dargon-project/thumbnail-generator"     "thumbnail-generator.csproj"; }

function dmiClientNestDaemon()   { (dmi "localhost:$CLIENT_NESTD_MANAGEMENT_PORT" &); }
