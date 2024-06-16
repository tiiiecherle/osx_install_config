#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### python wrapper and python script
###


### python changes
# python 3.11 implements the new PEP 668, marking python base environments as "externally managed"
# homebrew reflects these changes in python 3.12 and newer
# there are two recoomended ways of using python

# 1     usage of two special commands --break-system-packages --user (not used in this script)
# use python3 -m pip [command] --break-system-packages --user to install to /Users/$USER/Library/Python/3.xx/ (it does not break system packages, just a scary name)
# the disadvantage of this usage is that all python project would use the same directory/virtualenv and it would not be possible to use different versions of python or the packages for each project
# therefore the directory has to exist and has to be in PATH when using sudo -H -u "$loggedInUser" python3 -m pip [...]
#echo ''
#echo "using new PATH including user python directory..."
#PYTHON_VERSION_FOLDER_TO_CREATE="$(echo $PYTHON3_VERSION | awk '{print $2}' | awk -F'.' '{print $1 "." $2}')"
#sudo -H -u "$loggedInUser" mkdir -p /Users/"$loggedInUser"/Library/Python/"$PYTHON_VERSION_FOLDER_TO_CREATE"/bin
#PATH=$PATH:/Users/"$loggedInUser"/Library/Python/"$PYTHON_VERSION_FOLDER_TO_CREATE"/bin
#echo "$PATH"
#echo ''

# 2     virtual environments (used in this script)
# the best way is to create a virtual environment for each python usage/script/project and maintain them separately
# this gives the best fexiblility, testing possibilities and stability on the final used environment

PYTHON_PROJECT="finder_favourites"
PYTHON_VIRTUAL_ENVIRONMENT=/Users/"$USER"/Library/Python
PYTHON_VERSION="python3"

# python version outside virtual environment
echo ''
echo 'system python version incl. homebrew outside of the virtual environment...'
which "$PYTHON_VERSION"
"$PYTHON_VERSION" -V
echo ''

# creating python virtual environment
echo "creating and activating virtual python environment..."
"$PYTHON_VERSION" -m venv "$PYTHON_VIRTUAL_ENVIRONMENT"/"$PYTHON_PROJECT"
source "$PYTHON_VIRTUAL_ENVIRONMENT"/"$PYTHON_PROJECT"/bin/activate

# python version in virtual environment
echo ''
echo 'virtual environment python version...'
which "$PYTHON_VERSION"
"$PYTHON_VERSION" -V

# installing dependencies into virtual python environment
echo ''
echo "installing requirements..."
"$PYTHON_VERSION" -m pip install pyobjc
#echo ''

# running python command
#TEST_VARIABLE="test text"
#"$PYTHON_VERSION" << EOF
#print('Print variable $TEST_VARIABLE...')
#EOF

"$PYTHON_VERSION" "$SCRIPT_DIR"/11g_finder_favorites.py

# deactivating / leaving virtual python environment
#echo ''
echo "deactivating virtual python environment..."
deactivate

# python version outside virtual environment
echo ''
echo 'system python version incl. homebrew outside of the virtual environment...'
which "$PYTHON_VERSION"
"$PYTHON_VERSION" -V

echo ''
echo 'done ;)'
echo ''