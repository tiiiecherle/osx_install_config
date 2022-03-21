#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables


    
###
### starting installation
###
    
# install or uninstall
VARIABLE_TO_CHECK="$CONT_SSH_BREW"
QUESTION_TO_ASK="do you want to install or uninstall ssh compatible with version ssh1 (i/u)? "
env_ask_for_variable
CONT_SSH_BREW="$VARIABLE_TO_CHECK"

# checking if online
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    echo ''
    
    if [[ "$CONT_SSH_BREW" == "i" || "$CONT1_BREW" == "install" ]]
    then
        ### install
        # https://apple.stackexchange.com/questions/255621/how-to-enable-ssh-v1-in-macos-sierra
                
        # activating caffeinate
        env_activating_caffeinate
        
        if command -v brew &> /dev/null
        then
            # installed
            BREW_PATH_PREFIX=$(brew --prefix)
        else
            # not installed
            echo "homebrew is not installed, exiting..."
            echo ''
            exit
        fi
        
        # updating homebrew
        echo ''
        echo "updating homebrew..."
        brew update
        #brew upgrade
        # forcing homebrew update to revert any local patch
        echo ''
        echo "forcing homebrew update to revert any local patch..."
        brew update --force > /dev/null 2>&1
        
        # uninstalling patched ssh versions and dependencies including all installed versions
        echo ''
        echo "uninstalling patch and older openssh version that is compatible with ssh1..."
        #brew uninstall formula_name --force
        brew uninstall openssh --force
        brew uninstall openssl --force
        #brew uninstall openssl@1.1 --force 2> /dev/null
        
        # installing patch and older openssh version that is compatible with ssh1
        echo ''
        echo "installing patch and older openssh version that is compatible with ssh1..."
        curl -fsSL https://raw.githubusercontent.com/boltomli/MyMacScripts/master/homebrew/homebrew-core.openssh.diff | patch "$BREW_PATH_PREFIX"/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/openssh.rb
        echo ''
        brew install openssh --with-ssh1
        
        # commenting out ssh1 incompatible ssh config entry
        # open trolCommander or Commander One
        # /Users/$USER/.ssh/config
        # comment out the following line
        #UseKeychain yes
        # save
        
        echo ''
        echo "disabling incompatible ssh1 entries in ssh config file..."
        sed -i '' '/UseKeychain/s/^/#/g' /Users/$USER/.ssh/config
        
        # deactivating caffeinate
        echo ''
        env_deactivating_caffeinate
        
        # checking openssh version and ssh1 compatibility
        echo ''
        echo "checking openssh version and ssh1 compatibility..."
        echo "should be "$BREW_PATH_PREFIX"/bin/ssh to be ssh1 compatible..."
        which ssh
        $(which ssh) -1 -V
            
        # using ssh1
        #"$BREW_PATH_PREFIX"/bin/ssh -1 ADDRESS -L PORT:IP:PORT
        
    elif [[ "$CONT_SSH_BREW" == "u" || "$CONT1_BREW" == "uninstall" ]]
    then
        ### uninstall
        # brew cleanup <formula>
        # or
        brew cleanup
        brew cleanup --prune=0
        # should do the same withou output, but just to make sure              
        rm -rf $(brew --cache)
        
        # uninstalling patched ssh versions and dependencies including all installed versions
        #echo ''
        echo "uninstalling patch and older openssh version that is compatible with ssh1..."
        #brew uninstall formula_name --force
        brew uninstall openssh --force
        brew uninstall openssl --force
        #brew uninstall openssl@1.1 --force 2> /dev/null
        
        # forcing homebrew update to revert any local patch
        echo ''
        echo "forcing homebrew update to revert any local patch..."
        brew update --force > /dev/null 2>&1
        
        # installing latest versions of openssl and openssh
        #echo ''
        #echo "installing latest versions of openssl and openssh..."
        #brew install openssl
        #brew install openssh
        #brew install openssl@1.1
        
        # checking openssh version
        echo ''
        echo "checking openssh version..."
        echo "should be /usr/bin/ssh..."
        which ssh
        $(which ssh) -V

        # uncommenting ssh1 incompatible ssh config entry
        echo ''
        echo "enabling incompatible ssh1 entries in ssh config file..."
        # removes one # at the beginning of a line matching the pattern
        #sed -i '' '/UseKeychain/s/^#//g' /Users/$USER/.ssh/config
        # removes all # at the beginning of a line matching the pattern
        sed -i '' '/UseKeychain/s/^#*//g' /Users/$USER/.ssh/config
    else
        echo "no valid input, exiting script..."
        exit
    fi
    
else
    # offline
    echo "exiting..."
    echo ''
    exit
fi
 
# done
echo ''
echo "done ;)"
echo ''

###
### unsetting password
###

unset SUDOPASSWORD
