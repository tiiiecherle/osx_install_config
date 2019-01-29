#!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")


###
### script frame
###

# if script is run standalone, not sourced from another script, load script frame
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    # script is sourced
    :
else
    # script is not sourced, run standalone
    if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
    then
        . "$SCRIPT_DIR"/1_script_frame.sh
    else
        echo ''
        echo "script for functions and prerequisits is missing, exiting..."
        echo ''
        exit
    fi
fi


###
### command line tools
###

checking_command_line_tools


###
### homebrew
###

checking_homebrew
homebrew_update


### keepingyouawake
if [[ "$KEEPINGYOUAWAKE" != "active" ]]
then
    echo ''
    activating_keepingyouawake
    echo ''
else
    echo ''
fi


### parallel
checking_parallel


### starting sudo
start_sudo

# installing homebrew packages
#echo ''
echo "installing homebrew packages..."
echo ''

# installing formulae
homebrewpackages=$(cat "$SCRIPT_DIR"/_lists/01_homebrew_packages.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
if [[ "$homebrewpackages" == "" ]]
then
	:
else
    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
    then
        old_IFS=$IFS
        IFS=$'\n'
        for homebrewpackage_to_install in ${homebrewpackages[@]}
    	do
        IFS=$old_IFS
    	    echo installing formula "$homebrewpackage_to_install"...
    		#${USE_PASSWORD} | brew install "$homebrewpackage_to_install" 2> /dev/null | grep "/Cellar/.*files,\|Installing.*dependency"
    		${USE_PASSWORD} | brew install "$homebrewpackage_to_install"
    	echo ''
    	done
        # does not work parallel because of dependencies and brew requirements
        # parallel brew processes sometimes not finish install, give errors or hang
    else
        ### option 1 for including the list in the script
        #${USE_PASSWORD} | brew install "${homebrewpackages[@]}"
        
        ### option 2 for separate list file
        ${USE_PASSWORD} | brew install ${homebrewpackages[@]}
    fi
    
    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
    then
        #echo ''
        # parallel install not working, do not put a & at the end of the line or the script would hang and not finish
        #${USE_PASSWORD} | brew reinstall ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265 2> /dev/null | grep "/Cellar/.*files,"
        #${USE_PASSWORD} | brew reinstall ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
        # versions > 4.0.2_1 include h265 by default, so rebuilding does not seem to be needed any more
        if [[ $(ffmpeg -codecs 2>&1 | grep "\-\-enable-libx265") == "" ]]
        then
            #echo "installing formula ffmpeg with x265..."
            #${USE_PASSWORD} | HOMEBREW_DEVELOPER=1 brew reinstall --build-from-source ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
            :
        else
            :
        fi
    else
        #${USE_PASSWORD} | brew reinstall ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
        # versions > 4.0.2_1 include h265 by default, so rebuilding does not seem to be needed any more
        if [[ $(ffmpeg -codecs 2>&1 | grep "\-\-enable-libx265") == "" ]]
        then
            #echo "installing formula ffmpeg with x265..."
            #${USE_PASSWORD} | HOMEBREW_DEVELOPER=1 brew reinstall --build-from-source ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
            :
        else
            :
        fi
    fi
    # ffmpeg 
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
    if [[ $(brew list | grep qtfaststart) != "" ]]
    then
        brew link --overwrite qtfaststart
        echo ''
    else
        :
    fi
fi

# if script is run standalone, not sourced from another script, load script frame
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    # script is sourced
    :
else
    # script is not sourced, it is run standalone

    # cleaning up
    echo ''
    echo "cleaning up..."
    cleanup_all_homebrew
    
    CHECK_IF_CASKS_INSTALLED="no"
    CHECK_IF_MASAPPS_INSTALLED="no"
    . "$SCRIPT_DIR"/7_formulae_and_casks_install_check.sh
fi
    

### stopping sudo
stop_sudo
