function pushdRepos()   { pushd $DARGON_REPOSITORIES_DIR; }

function dargonUtilitiesVersion() {
   pushd $DARGON_DEVELOPER_SCRIPTS_DIR > /dev/null;
   git rev-parse HEAD;
   popd > /dev/null;
}

function dargonUtilitiesUpdate() {
   pushd $DARGON_DEVELOPER_SCRIPTS_DIR > /dev/null;
   git pull;
   popd > /dev/null;
}

function dargonUtilitiesReload() {
   . ~/.bashrc;
}

#
# Iterates through all repositories and runs the given command.
# Arguments:
#    $1  - Operation description
#    ... - The command to execute.
# Example:
#    dargonForeach "Printing paths to repositories" pwd;
function dargonForeach() {
   echo $1;
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      pushd "$DARGON_REPOSITORIES_DIR/$i" > /dev/null;
      echo -n -e "$COLOR_LIME$i: $COLOR_NONE";
      ${*:2};
      popd > /dev/null;
   done
   popd > /dev/null
}

function dargonNugetPackageRestore() {
   __updateNugetEverything;

   dargonForeach "Restoring NuGet packages..." _dargonBuild_restoreNugetPackages;
}

#
# Runs git pull [args] for each repo.
# Arguments:
#    ... - Additional arguments for git.
# Examples:
#    dargonPull, dargonPull origin master
function dargonPull() { dargonForeach "Pulling latest Dargon source code..." git pull $@; }

#
# Runs a git diff for each repo.
# Arguments:
#    ... - Additional arguments for git.
# Examples:
#    dargonDiff, dargonDiff origin/master
#
function dargonDiff() { dargonForeach "Diffing local repositories..." git --no-pager diff $@; }

#
# Runs git status for each repo.
#
function dargonStatus() { dargonForeach "Getting local repository statuses..." git status $@; }

#
# Runs git fsck for each repo.
#
function dargonFsck() { dargonForeach "Running Git Filesystem Consistency Check on local repositories..." git fsck $@; }

function dargonNukeVirtualMachines() {
   __updateDockerEverything;
   if [ ! $is_docker_installed ]
   then
      echo "ERROR: Docker is not installed!";
   else
      eval "b2d $DARGON_DOCKER_ARGS destroy";
   fi
}

function _dargonBuildAll() {
   echo "Building $1 with commands $2*";

   compgen -A function | grep "^$2" | while read -r commandName ; do
      echo "";
      ($commandName ${*:3}) || return 1;
   done

   local failed=$?;

   echo "";
   if [[ $failed -gt 0 ]]; then
      echo -e "${COLOR_RED}Build Failed.${COLOR_NONE}";
   else
      echo -e "${COLOR_LIME}Build Succeeded.${COLOR_NONE}";
   fi
}

function _dargonPrebuildSetupDevelopmentNest() {
   local nestName=$1;
   if [[ -z "$nestName" ]]; then
     echo "Empty nestName";
     return 1;
   fi

   echo -e "== ${COLOR_LIME}Setup Nest $nestName${COLOR_NONE} =="

   local packageConfig=`cat $DARGON_DEVELOPER_SCRIPTS_DIR/deploy/$nestName.json`
   local semver=`echo "$packageConfig" | grep version | cut -d ":" -f 2 | cut -d "\"" -f 2`;
   local major=`echo $semver | cut -d\. -f1`;
   local minor=`echo $semver | cut -d\. -f2`;
   local patchAndPrerelease=`echo $semver | cut -d\. -f3`;
   local patch=`echo $patchAndPrerelease | cut -d- -f1`;
   if [[ $patchAndPrerelease == *"-"* ]]; then
      echo "${COLOR_RED}Warning: Found prerelease in deploy file for $nestName.${COLOR_NONE}";
      local prerelease=`echo $patchAndPrerelease | cut -d- -f2`;
   fi
   local bumpedPatch=$(($patch + 1));
   local bumpedSemver="$major.$minor.$bumpedPatch-dev";

   echo "Deployed version of $nestName: $semver";
   echo "Development version of $nestName: $bumpedSemver";

   mkdir "$NEST_ROOT_DIR/$nestName" -p;
   echo "$bumpedSemver" > "$NEST_ROOT_DIR/$nestName/VERSION";
}

function _dargonBuildEgg() {
   local nestName=$1;
   local eggName=$2;
   local projectDirPath=$3;
   local projectFileName=$4;

   if [[ -z "$nestName" ]]; then
      echo "Empty nestName";
      return 1;
   elif [[ -z "$eggName" ]]; then
      echo "Empty eggName";
      return 1;
   elif [[ -z "$projectDirPath" ]]; then
      echo "Empty projectDirPath";
      return 1;
   elif [[ -z "$projectFileName" ]]; then
      echo "Empty projectFileName";
      return 1;
   fi

   echo -e "== $COLOR_LIME$eggName$COLOR_NONE =="

   __updateNugetEverything;
   __updateMsbuildEverything;
   __updateDargonNestEverything;

   pushd "$DARGON_REPOSITORIES_DIR/$projectDirPath" > /dev/null;
   if [ $? -ne 0 ]; then
      echo "Failed to cd to $DARGON_REPOSITORIES_DIR/$projectDirPath";
      return 1;
   else
      echo -e "${COLOR_CYAN}Restoring Packages:${COLOR_NONE}"
      _dargonBuild_restoreNugetPackages || return 1;
      echo -e ""

      echo -e "${COLOR_CYAN}Build Project:${COLOR_NONE}"
      msbuild /target:Clean,Build /property:Configuration=Debug /property:OutDir=./bin/temp/ /verbosity:m "$projectFileName" || return 1;
      echo -e ""

      echo -e "${COLOR_CYAN}Cleaning Egg Directory:${COLOR_NONE}";
      mkdir $NEST_ROOT_DIR/$nestName/$eggName -p;
      rm -rf $NEST_ROOT_DIR/$nestName/$eggName/* || return 1;
      echo "Done.";
      echo -e "";

      echo -e "${COLOR_CYAN}Create Egg:${COLOR_NONE}"
      nest --nest-path=$NEST_ROOT_DIR/$nestName create-egg "$eggName" 'dev' './bin/temp/' || return 1;
      popd > /dev/null;
   fi
}

function _dargonBuild_restoreNugetPackages() {
   if [ -f "NuGet.Config" ]; then
      nuget restore;
   elif [[ "$PWD" == "/" ]]; then
      echo "WARNING: Reached root directory but did not find NuGet.Config!";
      return 1;
   else
      pushd .. > /dev/null;
      _dargonBuild_restoreNugetPackages;
      local retval=$?;
      popd > /dev/null;
      return $retval;
   fi
}

function _dargonStart() {
   for command in "$@"; do
      echo "Executing: $command";
      $command || local failed=1;

      if [[ $failed ]]; then
         echo "";
         echo -e "${COLOR_RED}Startup Failed.${COLOR_NONE}";
         return 1;
      fi
   done
}
