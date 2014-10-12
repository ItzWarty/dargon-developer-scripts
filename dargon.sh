function dargonUtilitiesVersion() {
   pushd $DARGON_UTILITIES_DIR > /dev/null;
   git rev-parse HEAD;
   popd > /dev/null;
}

function dargonUtilitiesUpdate() {
   pushd $DARGON_UTILITIES_DIR > /dev/null;
   git pull;
   popd > /dev/null;
}

function dargonSetupEnvironment() {
   echo "TODO";
}

function dargonBuild() {
   echo "TODO";
}

function dargonRun() {
   echo "TODO";
}