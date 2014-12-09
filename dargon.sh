if [[ "$DARGON_UTILITIES_DIR" ]]; then export DARGON_DEVELOPER_SCRIPTS_DIR="$DARGON_UTILITIES_DIR"; fi
if [[ -z "$DARGON_DEVELOPER_SCRIPTS_DIR" ]]; then echo "Warning: \$DARGON_DEVELOPER_SCRIPTS_DIR ISN'T SET!"; fi
if [[ -z "$DARGON_REPOSITORIES_DIR" ]]; then echo "Warning: \$DARGON_REPOSITORIES_DIR ISN'T SET!"; fi

WYVERN_DOCKER_SSH_PORT=2122;
WYVERN_DOCKER_ARGS="--vm='wyvern-vm' --sshport=$WYVERN_DOCKER_SSH_PORT";
DARGON_RUBY_VERSION="2.1.3";
declare -a DARGON_REPOSITORY_NAMES=( '_default-c-sharp-repo' 'dargon-documentation' 'dargon.management-interface' 'dargon-developer-scripts' 'Dargon.Nest' 'Dargon.TestUtilities' 'libdargon.filesystem-api' 'libdargon.filesystem-impl' 'libdargon.management-api' 'libdargon.management-impl' 'libdargon.utilities' 'libdipc' 'libdnode' 'libdsp' 'libdtp' 'libdpo' 'libimdg' 'libinibin' 'librads' 'libvfm' 'the-dargon-project' 'libwarty' 'libwarty.proxies-api' 'libwarty.proxies-impl' 'NMockito' 'vssettings' );
DARGON_UTILITIES_TEMP_DIR="$DARGON_DEVELOPER_SCRIPTS_DIR/temp";
DARGON_GITHUB_ORGANIZATION_NAME="the-dargon-project";
RUBY_DIR_WIN="c:/Ruby21"
RUBY_DIR="/c/Ruby21"
BOOT2DOCKER_VERSION="v1.1.2";

COLOR_LIME='\e[1;32m';
COLOR_NONE='\e[0m';

if [ ! -e $DARGON_UTILITIES_TEMP_DIR ]
then
   mkdir $DARGON_UTILITIES_TEMP_DIR;
fi

# ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_boot2docker -p 2122 docker@127.0.0.1
# docker run --name web_container -d -i -p 8080:8080 -t akoeplinger/mono-aspnetvnext /bin/bash
# cd ~/containers/web
# docker build -t web
# http://download.mono-project.com/archive/3.2.3/windows-installer/mono-3.2.3-gtksharp-2.12.11-win32-0.exe (do compact installation)

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

function dargonSetupEnvironment() {
   command -v ruby >/dev/null 2>&1 || {
      dargonSetupEnvironment_installRuby;
   };
   command -v hub >/dev/null 2>&1 || {
      dargonSetupEnvironment_installHub;
   };
   command -v nuget >/dev/null 2>&1 || {
      dargonSetupEnvironment_installNuget;
   };
   
   __updateDockerEverything;
   if [ ! $is_docker_installed ]
   then
      dargonSetupEnvironment_installDocker;
   else 
      echo "DOCKER IS ALREADY INSTALLED";
   fi
   dargonSetupEnvironment_pullAndForkRepositories;
   dargonNugetPackageRestore;
   dargonStartWyvern;
   echo "TODO";
}

function dargonSetupEnvironment_installRuby() {
   echo "Installing Ruby $DARGON_RUBY_VERSION!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   local ruby_installer_name="ruby_installer_$DARGON_RUBY_VERSION.exe"
   local ruby_installer_path="$DARGON_UTILITIES_TEMP_DIR/$ruby_installer_name";
   curl -o $ruby_installer_path -O "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-$DARGON_RUBY_VERSION.exe?direct";
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

function dargonSetupEnvironment_installHub() {
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

function dargonSetupEnvironment_installNuget() {
   echo "Installing Nuget!";
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   local nuget_executable_name="nuget.exe"
   local nuget_executable_path="$DARGON_UTILITIES_TEMP_DIR/$nuget_executable_name";
   curl -L -o $nuget_executable_path -O "http://nuget.org/nuget.exe";
   popd > /dev/null;
   
   __updateNugetEverything;
}

function dargonSetupEnvironment_installDargonManagementInterface() {
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

function dargonSetupEnvironment_installBoot2Docker() {
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
}

function dargonSetupEnvironment_pullAndForkRepositories() {
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
      hub remote set-url origin;
      if [[ -z `git config remote.upstream.url` ]]
      then
         hub remote add upstream "$DARGON_GITHUB_ORGANIZATION_NAME/$i";
         echo "Created remote upstream"
      else
         hub remote set-url upstream "$DARGON_GITHUB_ORGANIZATION_NAME/$i";
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

function dargonNugetPackageRestore() {
   __updateNugetEverything;

   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Restoring Nuget Packages..."
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      pushd "$DARGON_REPOSITORIES_DIR/$i" > /dev/null;
      echo -n -e "$COLOR_LIME$i: $COLOR_NONE";
      eval "nuget restore";
      popd > /dev/null;      
   done
   popd > /dev/null
}

function dargonPullOrigin() {
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Pulling latest Dargon source code..."
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      pushd "$DARGON_REPOSITORIES_DIR/$i" > /dev/null;
      echo -n -e "$COLOR_LIME$i: $COLOR_NONE";
      git pull;
      popd > /dev/null;      
   done
   popd > /dev/null
}

function dargonPullUpstream() {
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Pulling latest Dargon source code..."
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      pushd "$DARGON_REPOSITORIES_DIR/$i" > /dev/null;
      echo -n -e "$COLOR_LIME$i: $COLOR_NONE";
      git pull upstream master;
      popd > /dev/null;      
   done
   popd > /dev/null
}

function dargonStatus() {
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Getting Dargon local repository statuses..."
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      pushd "$DARGON_REPOSITORIES_DIR/$i" > /dev/null;
      echo -n -e "$COLOR_LIME$i: $COLOR_NONE";
      git status;
      popd > /dev/null;      
   done
   popd > /dev/null
}

function dargonFsck() {
   pushd $DARGON_REPOSITORIES_DIR > /dev/null;
   echo "Running Git Filesystem Consistency Check on local repositories..."
   for i in "${DARGON_REPOSITORY_NAMES[@]}"
   do
      pushd "$DARGON_REPOSITORIES_DIR/$i" > /dev/null;
      echo -e "$COLOR_LIME$i: $COLOR_NONE";
      git fsck;
      popd > /dev/null;      
   done
   popd > /dev/null
}

function dargonNukeVirtualMachines() {
   __updateDockerEverything;
   if [ ! $is_docker_installed ] 
   then
      echo "ERROR: Docker is not installed!";
   else 
      eval "b2d $WYVERN_DOCKER_ARGS destroy";
   fi
}

function dargonBuild() {
   echo "TODO";
}

function dargonStart() {
   dargonStartWyvern;
}

function dargonStartWyvern() {
   echo "Running Wyvern";
   __updateDockerEverything;
   if [ ! $is_docker_installed ] 
   then
      echo "ERROR: Docker is not installed!";
   else 
      eval "b2d $WYVERN_DOCKER_ARGS init";
      eval "b2d $WYVERN_DOCKER_ARGS start";
   fi
}

function dargonDeployWyvern() {
   echo "Deploying Wyvern";
   __updateDockerEverything;
   if [ ! $is_docker_installed ] 
   then
      echo "ERROR: Docker is not installed!";
   else 
      scpWyvernDirectory "$DARGON_DEVELOPER_SCRIPTS_DIR/containers" "~/containers"
   fi
# scp your_username@remotehost.edu:foobar.txt /some/local/directory
}

function dargonStop() {
   dargonStopWyvern;
}

function dargonStopWyvern() {
   echo "Stopping Wyvern";
   __updateDockerEverything;
   if [ ! $is_docker_installed ] 
   then
      echo "ERROR: Docker is not installed!";
   else 
      eval "b2d $WYVERN_DOCKER_ARGS stop";
   fi
}

function sshWyvern() {
   ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_boot2docker -p $WYVERN_DOCKER_SSH_PORT docker@127.0.0.1;
}

function sshWyvernSilent() {
   sshWyvern &> /dev/null;
}

function sshWyvernMany() {
   local cmd="mkdir ~/test\nmkdir ~/test2";
   echo $cmd > sshWyvernSilent;
}

function scpWyvernDirectory() {
   scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_boot2docker -P $WYVERN_DOCKER_SSH_PORT -r $1 docker@127.0.0.1:$2
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

__updateDockerEverything;
__updateNugetEverything;
__updateDargonManagementInterfaceEverything;