
BOOT2DOCKER_VERSION="v1.4.1";

DARGON_RUBY_VERSION="2.1.3";

RUBY_DIR_WIN="c:/Ruby21"
RUBY_DIR="/c/Ruby21"

function dargonSetupEnvironment() {
   command -v ruby >/dev/null 2>&1 || {
      _dargonSetupEnvironment_installRuby;
   };
   command -v hub >/dev/null 2>&1 || {
      _dargonSetupEnvironment_installHub;
   };
   command -v nuget >/dev/null 2>&1 || {
      _dargonSetupEnvironment_installNuget;
   };
   
   _dargonSetupEnvironment_installDargonManagementInterface;
   _dargonSetupEnvironment_installNest;
   
   __updateDockerEverything;
   if [ ! $is_docker_installed ]
   then
      _dargonSetupEnvironment_installDocker;
   else 
      echo "DOCKER IS ALREADY INSTALLED";
   fi
   _dargonSetupEnvironment_pullRepositories;
   dargonNugetPackageRestore;
   dargonStartWyvern;
   echo "TODO";
}

function _dargonSetupEnvironment_installRuby() {
   echo "Installing Ruby $DARGON_RUBY_VERSION!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   local ruby_installer_name="ruby_installer_$DARGON_RUBY_VERSION.exe"
   local ruby_installer_path="$DARGON_UTILITIES_TEMP_DIR/$ruby_installer_name";
   curl -L -o $ruby_installer_path "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-$DARGON_RUBY_VERSION.exe";
   echo "Running Ruby Installer!";
   pushd $DARGON_UTILITIES_TEMP_DIR > /dev/null;
   cmd <<< "$ruby_installer_name /verysilent /LOADINF=$RUBY_SETTINGS_FILE_NAME /dir=$RUBY_DIR_WIN /tasks=modpath" >> /dev/null;
   popd > /dev/null;
   popd > /dev/null;
   
   # add ruby to path 
   source ~/.bashrc; 
   export PATH="$RUBY_DIR/bin:$PATH"
   echo "Done installing Ruby!";
}

function _dargonSetupEnvironment_installHub() {
   echo "Installing Hub!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   if [ ! -e hub ]
   then
      git clone git://github.com/github/hub.git;
   fi
   cd hub;
   git reset --hard 12445c14fea2e38eaba28edf5527c9b674692dd0;
   rake install;
   popd > /dev/null;
   echo "Done installing Hub!";
}

function _dargonSetupEnvironment_installNuget() {
   echo "Installing Nuget!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   local nuget_executable_name="nuget.exe"
   local nuget_executable_path="$DARGON_UTILITIES_TEMP_DIR/$nuget_executable_name";
   curl -L -o $nuget_executable_path -O "http://nuget.org/nuget.exe";
   popd > /dev/null;
   
   __updateNugetEverything;
}

function _dargonSetupEnvironment_installDargonManagementInterface() {
   echo "Installing Dargon Management Interface (dmi)!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   local dmi_executable_name="dmi.exe"
   local dmi_executable_path="$DARGON_UTILITIES_TEMP_DIR/$dmi_executable_name";
   local dmi_url=`curl -s https://api.github.com/repos/the-dargon-project/dargon.management-interface/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4`;
   echo "DMI Url: $dmi_url";
   curl -L -o $dmi_executable_path -O "$dmi_url";
   popd > /dev/null;
   
   __updateDargonManagementInterfaceEverything;
}

function _dargonSetupEnvironment_installNest() {
   echo "Installing Dargon Nest Command-Line Tool (nest)!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   local nest_executable_name="nest.exe"
   local nest_executable_path="$DARGON_UTILITIES_TEMP_DIR/$nest_executable_name";
   local nest_url=`curl -s https://api.github.com/repos/the-dargon-project/Dargon.Nest/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4`;
   echo "Nest Url: $nest_url";
   curl -L -o $nest_executable_path -O "$nest_url";
   popd > /dev/null;
   
   __updateDargonNestEverything;
}

function _dargonSetupEnvironment_installBoot2Docker() {
   echo "Installing Boot2Docker!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   local b2d_installer_name="b2d_installer_$BOOT2DOCKER_VERSION.exe"
   local b2d_installer_path="$DARGON_UTILITIES_TEMP_DIR/$b2d_installer_name";
   echo "https://github.com/boot2docker/windows-installer/releases/download/$BOOT2DOCKER_VERSION/docker-install.exe";
   curl -L -o $b2d_installer_path -O "https://github.com/boot2docker/windows-installer/releases/download/$BOOT2DOCKER_VERSION/docker-install.exe";
   echo "Running Boot2Docker Installer!";
   pushd $DARGON_UTILITIES_TEMP_DIR > /dev/null;
   cmd <<< "$b2d_installer_name /verysilent" >> /dev/null;
   popd > /dev/null;
   popd > /dev/null;
   
   __updateDockerEverything;
   __updateVirtualBoxEverything;
}

function _dargonSetupEnvironment_pullRepositories() {
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Pulling Dargon source code..."
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      echo -n -e "$COLOR_LIME$i: $COLOR_NONE";
      local repositoryPath="$DARGON_REPOSITORIES_DIR/$i";
      if [[ ! -d "$repositoryPath/.git" ]]
      then
         mkdir $repositoryPath > /dev/null;
         pushd $repositoryPath > /dev/null;
         hub clone "$DARGON_GITHUB_ORGANIZATION_NAME/$i" .;
         popd > /dev/null;
      fi
   done
   popd > /dev/null
}

function _dargonSetupEnvironment_pullAndForkRepositories() {
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Pulling and forking Dargon source code..."
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      echo -n -e "$COLOR_LIME$i: $COLOR_NONE";
      local repositoryPath="$DARGON_REPOSITORIES_DIR/$i";
      if [[ ! -d "$repositoryPath/.git" ]]
      then
         mkdir $repositoryPath > /dev/null;
         pushd $repositoryPath > /dev/null;
         hub clone "$DARGON_GITHUB_ORGANIZATION_NAME/$i" .;
         hub fork --no-remote;
         popd > /dev/null;
      fi
      pushd $repositoryPath > /dev/null;
      hub remote set-url -p origin;
      if [[ -z `git config remote.upstream.url` ]]
      then
         hub remote add -p upstream "$DARGON_GITHUB_ORGANIZATION_NAME/$i";
         echo "Created remote upstream"
      else
         hub remote set-url -p upstream "$DARGON_GITHUB_ORGANIZATION_NAME/$i";
         echo "Updated remote upstream"
      fi
      
      local branch="$(git symbolic-ref HEAD 2>/dev/null)" || "";     # detached HEAD
      if [[ ! -z "$branch" ]]
      then
         branch=${branch##refs/heads/};
         #git branch -u is git 1.8+, else fall back to old argument.
         git branch -u "origin/$branch" > /dev/null || git branch --set-upstream $branch "origin/$branch" > /dev/null;
         echo "Upstream set to origin/$branch";
      else 
         echo "Not on a branch?";
      fi
      popd > /dev/null;
   done
   popd > /dev/null
}

function _dargonSetupEnvironment_setupAggregateRepository() {
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Setting up dargon-aggregate repository..."
   
   if [[ ! -d "dargon-aggregate" ]]
   then
      mkdir "dargon-aggregate" > /dev/null;
   fi
   pushd "dargon-aggregate" > /dev/null;
   
   if [[ ! -d ".git" ]]
   then
      git init > /dev/null;
   fi
   
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      echo -n -e "$COLOR_LIMEConfigure $i: $COLOR_NONE";
      hub remote add -p "$i" "$DARGON_GITHUB_ORGANIZATION_NAME/$i";
   done
   popd > /dev/null
}

function __updateDockerEverything() {
   __updateDockerGlobals
   if [ $is_docker_installed ]
   then
      alias boot2docker="'$boot2docker_path'";
      alias b2d="'$boot2docker_path'";
   fi
}

function __updateDockerGlobals() {
   local path="/c/Program Files/Boot2Docker for Windows/boot2docker.exe";
   if [ -e "$path" ]
   then     
      is_docker_installed=1;
      boot2docker_path=$path;
   else 
      unset is_docker_installed;
      unset boot2docker_path;
   fi
}

function __updateNugetEverything() {
   local path="$DARGON_UTILITIES_TEMP_DIR/nuget.exe";
   if [ -e "$path" ]
   then
      alias nuget="'$path'";
   fi
}

function __updateVirtualBoxEverything() {
   local path="/c/Program Files/Oracle/VirtualBox";
   if [ -e "$path" ]
   then
    export PATH="$path:$PATH"
   fi
}

function __updateKvmEverything() {
   alias kvm="cmd /R kvm";
}

function __updateMsbuildEverything() {
   if [ -e "$MSBUILD_DIR" ]
   then
      alias msbuild="'$MSBUILD_DIR/MSBuild.exe'";
      alias csc="'$MSBUILD_DIR/csc.exe'";
   fi
}

# DMI ILMerge Command: "C:\Program Files (x86)\Microsoft\ILMerge\ILMerge.exe" "C:\my-repositories\dargon.management-interface\bin\Release\dargon.management-interface.exe" "C:\my-repositories\dargon.management-interface\bin\Release\*.dll" /targetplatform:v4 /out:C:/my-repositories/dargon.management-interface\bin\Release/dmi.exe /wildcards
function __updateDargonManagementInterfaceEverything() {
   local path="$DARGON_UTILITIES_TEMP_DIR/dmi.exe";
   if [ -e "$path" ]
   then
      function dmi { "$DARGON_UTILITIES_TEMP_DIR/dmi.exe" "$1" > /dev/null; }
      export -f dmi;
      alias dmiDaemon="dmi localhost:21000 &";
      alias dmiPlatform="dmi localhost:31000 &";
   fi
}
function __updateDargonNestEverything() {
   local path="$DARGON_UTILITIES_TEMP_DIR/nest.exe";
   if [ -e "$path" ]
   then
      function nest { "$DARGON_UTILITIES_TEMP_DIR/nest.exe" "$@"; }
      export -f nest;
   fi
}

# NuSpecGen ILMerge Command: "C:\Program Files (x86)\Microsoft\ILMerge\ILMerge.exe" "C:\my-repositories\NuSpecGen\bin\Release\NuSpecGen.exe" "C:\my-repositories\NuSpecGen\bin\Release\*.dll" /targetplatform:v4 /out:C:/my-repositories/NuSpecGen\bin\Release/ilmerge/NuSpecGen.exe /wildcards
function __updateNuSpecGenEverything() {
   local path="$DARGON_UTILITIES_TEMP_DIR/NuSpecGen.exe";
   if [ -e "$path" ]
   then
      function NuSpecGen { "$DARGON_UTILITIES_TEMP_DIR/NuSpecGen.exe" "$@"; }
      export -f NuSpecGen;
   fi
}

function __updateConemuEverything() {
   alias conemu="'$CONEMU_PATH'";
   # cmd <<< "\"$CONEMU_PATH\" /title platform-hydar /cmdlist \"cmd /c dir -cur_console:f ||| cmd /c dir -cur_console:s1TV ||| cmd /c dir -cur_console:s1TH ||| cmd /c dir -cur_console:s2TH"
}

__updateDockerEverything;
__updateNugetEverything;
__updateDargonManagementInterfaceEverything;
__updateDargonNestEverything;
__updateNuSpecGenEverything;
__updateVirtualBoxEverything;
__updateKvmEverything;
__updateMsbuildEverything;
__updateConemuEverything;
