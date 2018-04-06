#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search



        
    # cleaning up
    echo ''
    echo "cleaning up..."
    
    brew cleanup
    brew cask cleanup
    
    # checking if successfully installed
    . "$SCRIPT_DIR"/5e_homebrew_and_cask_install_check.sh
    
    # done
    echo ''
    echo "homebrew and cask install script done ;)"
    echo ''
    
    # deactivating keepingyouawake
    deactivating_keepingyouawake

else
    echo "not online, skipping installation..."
    echo ''
fi

###
### unsetting password
###

unset SUDOPASSWORD
