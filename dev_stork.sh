export DARGON_STORK_DIR="$DARGON_DEVELOPER_SCRIPTS_DIR/stork";
export DARGON_STORK_DEPLOY_CONFIG_DIR="$DARGON_DEVELOPER_SCRIPTS_DIR/deploy";

function storkPrepareDeploy() {
   local channel=$1;
   _storkExec prepare_deploy $1;
}

function storkExecuteDeploy() {
   local channel=$1;
   _storkExec execute_deploy $1;
}

function _storkExec { ruby "$DARGON_STORK_DIR/main.rb" $@; }
