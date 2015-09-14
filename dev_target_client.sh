function pushdCore()    { pushd "$DARGON_REPOSITORIES_DIR/the-dargon-project"; }

function clientStartHeadless()   { _dargonStart _clientStartNestD _clientStartCoreD; }
function clientStartWithGui()    { _dargonStart clientStartHeadless _clientStartManager; }
function clientStartWithCli()    { _dargonStart clientStartHeadless _clientStartCli; }

function clientBuild()           { _dargonBuildAll "Dargon Client" _clientBuild; }

function _clientStartNestD()     { _nestStartDaemon -p 21999 $@; }
function _clientStartEgg()       { _nestStartEgg -p 21999 -e $1 ; }
function _clientStartCoreD()     { _clientStartEgg "cored"; }
function _clientStartManager()   { _clientStartEgg "dargon-client"; }
function _clientStartThumbGen()  { _clientStartEgg "thumbnail-generator"; }
function _clientStartCli()       { eval "$NEST_DIR/dargon-cli/dargon-cli.exe"; }

function _clientBuildCoreDaemon()            { _dargonBuildEgg "cored"                 "the-dargon-project/daemon-impl"             "daemon-impl.csproj"; }
function _clientBuildClient()                { _dargonBuildEgg "dargon-client"         "the-dargon-project/dargon-client"           "dargon-client.csproj"; }
function _clientBuildCli()                   { _dargonBuildEgg "dargon-cli"            "the-dargon-project/dargon-cli"              "dargon-cli.csproj"; }
function _clientBuildTrinket()               { _dargonBuildEgg "trinket"               "the-dargon-project/trinket-proxy-impl"      "trinket-proxy-impl.csproj"; }
function _clientBuildTrinketDim()            { _dargonBuildEgg "trinket-dim"           "the-dargon-project/DargonInjectedModule"    "Dargon - Injected Module.vcxproj"; }
function _clientBuildThumbnailGenerator()    { _dargonBuildEgg "thumbnail-generator"   "the-dargon-project/thumbnail-generator"     "thumbnail-generator.csproj"; }

function _clientBuildNestSpawner() {
   # Build nest-spawner to $NEST_DIR/nest-spawner
   _dargonBuildEgg "nest-spawner" "Dargon.Nest/nest-spawner" "nest-spawner.csproj";
   
   # ILMerge nest-spawner to nest-spawner.exe
   mkdir "$NEST_DIR/nest-spawner/merged";
   local WINDOWS_NEST_DIR="$(toWindowsPath $NEST_DIR)";
   cmd <<< "\"C:/Program Files (x86)/Microsoft/ILMerge/ILMerge.exe\" \"$WINDOWS_NEST_DIR/nest-spawner/nest-spawner.exe\" \"$WINDOWS_NEST_DIR/nest-spawner/*.dll\" /targetplatform:v4 /out:$WINDOWS_NEST_DIR/nest-spawner/merged/nest-spawner.exe /wildcards /lib:\"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF\"";
   
   # cd to nest-spawner
   pushd "$NEST_DIR/nest-spawner" > /dev/null;
      
   # Remove old nest-spawner files
   rm *.pdb *.dll *.exe *.config;
   
   # Move ILMerged files to nest-spawner directory, delete merged directory.
   mv merged/* . && rmdir merged;
   
   # Update filelist to only contain nest-spawner.exe
   cat "filelist" | grep "nest-spawner.exe$" | tr -d '\n' > "filelist_temp";
   rm filelist;
   mv "filelist_temp" "filelist";
   
   # return to original directory.
   popd > /dev/null;
}