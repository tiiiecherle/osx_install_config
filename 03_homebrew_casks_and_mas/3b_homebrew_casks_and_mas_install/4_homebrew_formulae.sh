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
### script frame
###

if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
then
    . "$SCRIPT_DIR"/1_script_frame.sh
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
else
    echo ''
    echo "script for functions and prerequisits is missing, exiting..."
    echo ''
    exit
fi



###
### command line tools
###

echo ''
env_command_line_tools_install_shell


###
### homebrew
###


### checking homebrew
checking_homebrew
env_homebrew_update


### activating caffeinate
env_activating_caffeinate


### parallel
env_check_if_parallel_is_installed


### starting sudo
env_start_sudo

# installing homebrew formulae
#echo ''
echo "installing homebrew formulae..."
echo ''

# installing formulae
homebrew_formulae=$(cat "$SCRIPT_DIR"/_lists/01_homebrew_formulae.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
if [[ "$homebrew_formulae" == "" ]]
then
	echo ''
else

    ### installations
    # no parallel installs supported for formulae due to dependencies and brew requirements
    # parallel brew processes sometimes not finish install, give errors or hang
    
    # does not work as of 2021-09-13 du to this issue
    # https://github.com/Homebrew/brew/issues/12034#issuecomment-917261527
    install_formulae() {
	    while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
	        homebre_formula_to_install="$line"
	        if [[ $(brew list --formulae | tr "," "\n" | grep "^$line$") == "" ]]
	        then
	            echo "installing formula "$homebre_formula_to_install"..."
			    #env_use_password | brew install --formula "$homebre_formula_to_install" 2> /dev/null | grep "/Cellar/.*files,\|Installing.*dependency"
			    #env_use_password | brew install --formula "$homebre_formula_to_install"
			    brew install --formula "$homebre_formula_to_install"
		        echo ''
		    else
		        echo "formula "$line" already installed..."
		        echo ''
		    fi
		done <<< "$(printf "%s\n" "${homebrew_formulae[@]}")"
	}
	#install_formulae
	
	if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
		# workaround with parallel
		install_formulae_parallel() {
	        homebre_formula_to_install="$1"
	        if [[ $(brew list --formulae | tr "," "\n" | grep "^$line$") == "" ]]
	        then
	            echo "installing formula "$homebre_formula_to_install"..."
			    # preserver colored output using script
	            script -q /dev/null brew install --formula "$homebre_formula_to_install"
	            # the following is should not be needed and is showing the password in clear text as of 2021-09-12
	            #builtin printf "$SUDOPASSWORD\n" | script -q /dev/null brew install --formula "$homebre_formula_to_install"
		        echo ''
		    else
		        echo "formula "$line" already installed..."
		        echo ''
		    fi
		}
		if [[ "$(printf "%s\n" "${homebrew_formulae[@]}")" != "" ]]; then env_parallel --will-cite -j"1" --line-buffer -k "install_formulae_parallel {}" ::: "$(printf "%s\n" "${homebrew_formulae[@]}")"; fi
	else
		# workaround without parallel
		brew install --formula $(printf "%s\n" "${homebrew_formulae[@]}")
	fi
    
    
    ### ffmpeg 
    # versions > 4.0.2_1 include h265 by default, so rebuilding does not seem to be needed any more
    if [[ $(ffmpeg -codecs 2>&1 | grep "\-\-enable-libx265") == "" ]]
    then
        #echo "installing formula ffmpeg with x265..."
        #env_use_password | HOMEBREW_DEVELOPER=1 brew reinstall --build-from-source ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
        :
    else
        :
    fi

    # as command shows how the binary was compiled and if the options are really included / enabled
    # if not try (--build-from-source requires HOMEBREW_DEVELOPER=1)
    # HOMEBREW_DEVELOPER=1 brew reinstall --build-from-source --force ...
    # brew reinstall -s --force ...
    # if this is not working, install with option --HEAD which installs the current git version that is build from souce and compiled with all options
    
    # solving
    # Warning: You have unlinked kegs in your Cellar
    # Leaving kegs unlinked can lead to build-trouble and cause brews that depend on
    # those kegs to fail to run properly once built. Run `brew link` on these:
    # qtfaststart
    link_qtfaststart() {
        if [[ $(brew list --formula | grep "^qtfaststart$") != "" ]]
        then
            brew link --overwrite qtfaststart
            echo ''
        else
            :
        fi
    }
    link_qtfaststart
fi

# if script is run standalone, not sourced, clean up
if [[ "$SCRIPT_IS_SOURCED" == "yes" ]]
then
    # script is sourced
    :
else
    # script is not sourced, it is run standalone

    # cleaning up
    #echo ''
    echo "cleaning up..."
    env_cleanup_all_homebrew
    
    CHECK_IF_CASKS_INSTALLED="no" CHECK_IF_MASAPPS_INSTALLED="no" . "$SCRIPT_DIR"/7_formulae_casks_and_mas_install_check.sh
fi
    

### stopping sudo
env_stop_sudo


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
