#!/bin/bash

if [ $(id -u) -ne 0 ]
then
    echo "script has to be run as root, exiting..."
    exit
else
    :
fi

# run command as root
# echo 1

# run command as user
# sudo -u $SYSTEM_USER echo 1

