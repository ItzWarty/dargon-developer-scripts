COLOR_RED='\e[1;31m';
COLOR_LIME='\e[1;32m';
COLOR_CYAN='\e[1;36m';
COLOR_NONE='\e[0m';

#
# Converts a msys unix-style path to a windows path.
# usage: 
#    `echo "$(toWindowsPath /c/a thing)"` outputs `C:/a thing`
#
function toWindowsPath() {
   echo $@ | sed -e 's/^\///' -e 's/\//\\/g' -e 's/^./\0:/';
}

#
# Runs the given executable with the windows shell. 
#
# The function will handle process elevation where necessary. Script execution
# continues once the application has started (e.g. elevation prompt has been
# accepted); in other words, the executed application may block.
#
# Arguments: 
#   $1  - path - windows-style path to the executable
#   ... - additional arguments to be passed to the executable
#
# Example:
#   shellExecute cmd //c "timeout 5"
#
function shellExecute() {
   local path=$1;
   local args=${*:2};
   
   local command="$path $args"; 
   
   cmd //c start \"\" $command;
}