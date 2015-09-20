#expects SIGNTOOL_PATH and DARGON_PFX_PATH
export DARGON_STORK_DIR="$DARGON_DEVELOPER_SCRIPTS_DIR/stork";
export DARGON_STORK_DEPLOY_CONFIG_DIR="$DARGON_DEVELOPER_SCRIPTS_DIR/deploy";
export DARGON_STORK_STAGE_DIR="$DARGON_DEVELOPER_SCRIPTS_DIR/stage";

function storkPrepareDeploy() {
   local channel=$1;
   _storkExec prepare_deploy $1;
}

function storkExecuteDeploy() {
   local channel=$1;
   _storkExec execute_deploy $1;
}

function _storkSignFile() {
   local file_path=$1;
   local pfx_password=$2

   if [ -z "$pfx_password" ]; then
      if [ -z "$DARGON_PFX_PASSWORD" ]; then
         read -s -p "Enter Dargon PFX Password: " DARGON_PFX_PASSWORD
      fi
      local pfx_password=$DARGON_PFX_PASSWORD
   fi
   "$SIGNTOOL_PATH" 'sign' '-f' $DARGON_PFX_PATH -t http://timestamp.verisign.com/scripts/timstamp.dll -p $pfx_password $file_path
}

function _storkExec { ruby "$DARGON_STORK_DIR/main.rb" $@; }
