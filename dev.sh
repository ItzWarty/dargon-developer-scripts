if [[ "$DARGON_UTILITIES_DIR" ]]; then export DARGON_DEVELOPER_SCRIPTS_DIR="$DARGON_UTILITIES_DIR"; fi
if [[ -z "$DARGON_DEVELOPER_SCRIPTS_DIR" ]]; then echo "Warning: \$DARGON_DEVELOPER_SCRIPTS_DIR ISN'T SET!"; fi
if [[ -z "$DARGON_REPOSITORIES_DIR" ]]; then echo "Warning: \$DARGON_REPOSITORIES_DIR ISN'T SET!"; fi
if [[ -z "$MSBUILD_DIR" ]]; then echo "Warning: \$MSBUILD_DIR ISN'T SET!"; fi
if [[ "$NEST_DIR" ]]; then export NEST_ROOT_DIR="$NEST_DIR/nests"; fi
if [[ -z "$NEST_ROOT_DIR" ]]; then echo "Warning: \$NEST_ROOT_DIR ISN'T SET!"; fi

DARGON_GITHUB_ORGANIZATION_NAME="the-dargon-project";
declare -a DARGON_REPOSITORY_NAMES=( '_default-c-sharp-repo' 'dargon-documentation' 'Dargon.Hydar' 'dargon.management-interface' 'dargon-developer-scripts' 'Dargon.Nest' 'Dargon.TestUtilities' 'Dargon.FileSystems.Api' 'Dargon.FileSystems.Impl' 'libdargon.hydar-api' 'Dargon.Management.Api' 'Dargon.Management.Impl' 'Dargon.Utilities' 'libdipc' 'Dargon.IO' 'Dargon.Services' 'Dargon.Transport' 'Dargon.PortableObjects' 'libinibin' 'liblolskins' 'Dargon.RADS' 'liblolmap' 'libvfm' 'the-dargon-project' 'ItzWarty.Commons' 'ItzWarty.Proxies.Api' 'ItzWarty.Proxies.Impl' 'NMockito' 'dargon.modelviewer' 'vssettings' 'libdargon.hydar-local-impl' 'Dargon.SystemState.Api' 'Dargon.Platform' 'dockerfiles' 'Dargon.PortableObject.Streams');

DARGON_UTILITIES_TEMP_DIR="$DARGON_DEVELOPER_SCRIPTS_DIR/temp";
mkdir -p $DARGON_UTILITIES_TEMP_DIR;

source "$DARGON_DEVELOPER_SCRIPTS_DIR/dev_utilities.sh";
source "$DARGON_DEVELOPER_SCRIPTS_DIR/dev_setup.sh";
source "$DARGON_DEVELOPER_SCRIPTS_DIR/dev_dargon.sh";
source "$DARGON_DEVELOPER_SCRIPTS_DIR/dev_target_nest.sh";
source "$DARGON_DEVELOPER_SCRIPTS_DIR/dev_target_client.sh";
source "$DARGON_DEVELOPER_SCRIPTS_DIR/dev_target_platform.sh";
source "$DARGON_DEVELOPER_SCRIPTS_DIR/dev_stork.sh";
