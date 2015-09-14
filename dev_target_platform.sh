function pushdPlatform()    { pushd "$DARGON_REPOSITORIES_DIR/Dargon.Hydar"; }

function platformBuild()         { _dargonBuildAll "Dargon Platform" _platformBuild; }
function platformStart()         { _dargonStart _platformMigrate _platformStartNestD _platformStartZilean _platformStartCore _platformStartWebend; }

function _platformStartNestD()   { _nestStartDaemon -p 31999 -m 31000 $@; }
function _platformStartEgg()     { _nestStartEgg -p 31999 -e $1; }
function _platformStartZilean()  { _platformStartEgg "zileand"; }
function _platformStartCore()    { _platformStartEgg "platformd"; }
function _platformStartWebend()  { _platformStartEgg "webendd"; }

function _platformBuildZilean()  { _dargonBuildEgg "zileand" "Dargon.Zilean/zileand" "zileand.csproj"; }
function _platformBuildCore()    { _dargonBuildEgg "platformd" "Dargon.Hydar/platform" "platform.csproj"; }
function _platformBuildWebend()  { _dargonBuildEgg "webendd" "Dargon.Hydar/webend" "webend.csproj"; }

function _platformMigrate {
   __updateNugetEverything;
   __updateMsbuildEverything;
   
   echo -e "== ${COLOR_LIME}Platform Migrate:${COLOR_NONE} ==";
   pushd "$DARGON_REPOSITORIES_DIR/Dargon.Hydar" > /dev/null;
   
   echo -e "${COLOR_CYAN}Updating NuGet Packages:${COLOR_NONE}";
   _dargonBuild_restoreNugetPackages;
   echo -e ""
   
   echo -e "${COLOR_CYAN}Building platform-migrations:${COLOR_NONE}";
   pushd "platform-migrations" > /dev/null;
   eval "msbuild /target:Clean,Build /property:Configuration=Debug /property:OutDir=./bin/temp/ /verbosity:m";
   popd > /dev/null;
   echo -e ""
      
   echo -e "${COLOR_CYAN}Running Migrations:${COLOR_NONE}";
   "./packages/FluentMigrator.Tools.1.6.0/tools/x86/40/Migrate.exe" --connectionString "Server=127.0.0.1;Port=5432;Database=dargon;User Id=dargon_migrations;Password=dargon;" --db=Postgres --target="platform-migrations/bin/temp/platform-migrations.dll" "$@";
   echo -e ""
   
   echo -e "${COLOR_CYAN}Done.${COLOR_NONE}";
   popd > /dev/null;
}

function _platformMigrateRollbackAll {
   platformMigrate --task "rollback:all";
}

function _platformStartHydarCluster() {
   local path="$NEST_DIR/dev-hydar-example/dev-hydar-example.exe";
   # cmd <<< "\"$CONEMU_PATH\" /title dev-hydar-example /cmdlist \"bash -c \"$path\" -cur_console:f ||| bash -c \"$path\" -cur_console:s1TH"
   cmd <<< "\"$CONEMU_PATH\" /title dev-hydar-example /cmdlist \"bash -c \"$path -s 32001 -m 32101\" -cur_console:fc ||| bash -c \"$path -s 32002 -m 32102\" -cur_console:s1TVc ||| bash -c \"$path -s 32003 -m 32103\" -cur_console:s1THc ||| bash -c 'echo sleeping... && sleep 5 && $path -s 32004 -m 32104' -cur_console:s2THc"
   #cmd <<< "\"$CONEMU_PATH\" /title platform-hydar /cmdlist \"cmd /c $path -cur_console:f ||| cmd /c $path -cur_console:s1TV ||| cmd /c dir -cur_console:s1TH ||| cmd /c dir -cur_console:s2TH"
}