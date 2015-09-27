function nestBuild() { _dargonBuildAll "Dargon Nest" _nestBuild; }
function nestListProcesses() { WMIC PROCESS get ProcessId,CommandLine /format:csv | grep nest | cut -d ',' -f 2-; }

function _nestBuildCli()         { _dargonBuildEgg "dev"    "nest"               "Dargon.Nest/nest"               "nest.csproj"; }
function _nestBuildDaemon()      { _dargonBuildEgg "nest"   "nestd"              "Dargon.Nest/nestd"              "nestd.csproj"; }
function _nestBuildHost()        { _dargonBuildEgg "nest"   "nest-host"          "Dargon.Nest/nest-host"          "nest-host.csproj"; }
function _nestBuildExampleEgg()  { _dargonBuildEgg "dev"    "dev-egg-example"    "Dargon.Nest/dev-egg-example"    "dev-egg-example.csproj"; }
function _nestBuildCommander()   { _dargonBuildEgg "dev"    "dev-nest-commander" "Dargon.Nest/dev-nest-commander" "dev-nest-commander.csproj"; }

function _nestStartSpawner()     { ("$NEST_ROOT_DIR/dev/nest-spawner/nest-spawner.exe"); }
function _nestStartDaemon()      { shellExecute "$(toWindowsPath $NEST_ROOT_DIR/nest/nestd/nestd.exe)" $@; }
function _nestStartEgg()         { "$NEST_ROOT_DIR/dev/dev-nest-commander/dev-nest-commander.exe" -c spawn-egg $@; }
function _nestKill()             { "$NEST_ROOT_DIR/dev/dev-nest-commander/dev-nest-commander.exe" -c kill-nest $@; }
function _nestStartCli()         { cd $NEST_DIR && "$NEST_ROOT_DIR/dev/nest/nest.exe"; }

function _nestTryKill() {
   echo -e "==${COLOR_LIME} TryKill nestd $@ ${COLOR_NONE}=="
   echo "A time-out indicates nestd was not running.";
   _nestKill $@ -t 500;
   echo "";
}

function _nestBuildSpawner() {
   # Build nest-spawner to $NEST_DIR/nest-spawner
   _dargonBuildEgg "dev" "nest-spawner" "Dargon.Nest/nest-spawner" "nest-spawner.csproj";
   
   # ILMerge nest-spawner to nest-spawner.exe
   mkdir "$NEST_ROOT_DIR/dev/nest-spawner/merged";
   local WINDOWS_NEST_DIR="$(toWindowsPath $NEST_ROOT_DIR/dev)";
   cmd <<< "\"C:/Program Files (x86)/Microsoft/ILMerge/ILMerge.exe\" \"$WINDOWS_NEST_DIR/nest-spawner/nest-spawner.exe\" \"$WINDOWS_NEST_DIR/nest-spawner/*.dll\" /targetplatform:v4 /out:$WINDOWS_NEST_DIR/nest-spawner/merged/nest-spawner.exe /wildcards /lib:\"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\WPF\"";
   
   # cd to nest-spawner
   pushd "$NEST_ROOT_DIR/dev/nest-spawner" > /dev/null;
      
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