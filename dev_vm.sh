DARGON_DOCKER_SSH_PORT=2122;
DARGON_VM_NAME='dargon-vm';
DARGON_DOCKER_ARGS="--vm='$DARGON_VM_NAME' --sshport=$DARGON_DOCKER_SSH_PORT";

function dargonUp() {
   echo "Starting Docker VM";
   __updateDockerEverything;
   if [ ! $is_docker_installed ] 
   then
      echo "ERROR: Docker is not installed!";
   else 
      eval "b2d $DARGON_DOCKER_ARGS init";
      VBoxManage sharedfolder remove "$DARGON_VM_NAME" --name "dargon-repositories";
      VBoxManage sharedfolder add "$DARGON_VM_NAME" --name "dargon-repositories" --hostpath "$DARGON_REPOSITORIES_DIR" --readonly;
      eval "b2d $DARGON_DOCKER_ARGS start";
      sshDargon "sudo mkdir -p /dargon/repositories";
      sshDargon "sudo mount -t vboxsf -o uid=0 dargon-repositories /dargon/repositories";
   fi
}

function dargonDown() {
   echo "Stopping Docker VM";
   __updateDockerEverything;
   if [ ! $is_docker_installed ] 
   then
      echo "ERROR: Docker is not installed!";
   else 
      eval "b2d $DARGON_DOCKER_ARGS stop";
   fi
}

function sshDargon() {
   ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_boot2docker -p $DARGON_DOCKER_SSH_PORT docker@127.0.0.1 $1;
}

function sshDargonSilent() {
   eval "sshDargon '$cmd'" &> /dev/null;
}

function scpDargonDirectory() {
   scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/id_boot2docker -P $DARGON_DOCKER_SSH_PORT -r $1 docker@127.0.0.1:$2
}