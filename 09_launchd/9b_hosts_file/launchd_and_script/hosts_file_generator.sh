#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
    echo script is not run as root, exiting...
    exit
else

EXECTIME=$(date '+%Y-%m-%d %T')
LOGFILE=/var/log/hosts_file_update.log

if [ -f $LOGFILE ]
then
    # only macos takes care of creation time, linux doesn`t because it is not part of POSIX
    LOGFILEAGEINSECONDS="$(( $(date +"%s") - $(stat -f "%B" $LOGFILE) ))"
    MAXLOGFILEAGE=$(echo "30*24*60*60" | bc)
    #echo $LOGFILEAGEINSECONDS
    #echo $MAXLOGFILEAGE
    # deleting logfile after 30 days
    if [ "$LOGFILEAGEINSECONDS" -lt "$MAXLOGFILEAGE" ];
    then
        echo "logfile not older than 30 days..."
    else
        # deleting logfile
        echo "deleting logfile..."
        sudo rm $LOGFILE
        sudo touch $LOGFILE
        sudo chmod 644 $LOGFILE
        #sudo chmod 666 $LOGFILE
    fi
else
    sudo touch $LOGFILE
    sudo chmod 644 $LOGFILE
    #sudo chmod 666 $LOGFILE
fi

sudo echo "" >> $LOGFILE
sudo echo $EXECTIME >> $LOGFILE

hosts_file_install_update() {

    # checking modification date of /etc/hosts
    UPDATEEACHDAYS=4
    if [ "$(find /etc/* -name 'hosts' -type f -maxdepth 0 -mtime +"$UPDATEEACHDAYS"d | grep -x '/etc/hosts')" == "" ]
    then
        echo "/etc/hosts was already updated in the last "$UPDATEEACHDAYS" days, no need to update..."
        echo "exiting script..."
        exit
    else
        echo "/etc/hosts is older than "$UPDATEEACHDAYS" days, updating..."
    fi
    
    # giving the online check some time if run on laptop to switch to correct network profile on boot
    ping -c5 google.com > /dev/null 2>&1
    if [ "$?" = 0 ]
    then
        :
    else
        sleep 300
    fi
        
    # checking if online
    ping -c5 google.com > /dev/null 2>&1
    if [ "$?" = 0 ]
    then
        echo "we are online... updating hosts file..."
    
        # creating installation directory
        mkdir -p /Applications/hosts_file_generator/
    
        # downloading / updating hosts file creator from git repository
        if [ -d /Applications/hosts_file_generator/.git ];
        then
            # updating
            echo "updating hosts file generator..."
            if [ -d /Applications/hosts_file_generator/ ];
            then
                cd /Applications/hosts_file_generator/
                sudo git fetch --all
                sudo git reset --hard origin/master
                sudo git pull origin master
                cd -
            else
                :
            fi
        else
            # installing
            echo "downloading hosts file generator..."
            if [ -d /Applications/hosts_file_generator/ ];
            then
                sudo rm -rf /Applications/hosts_file_generator/
                mkdir -p /Applications/hosts_file_generator/
                git clone --depth 5 https://github.com/StevenBlack/hosts.git /Applications/hosts_file_generator/
            else
                :
            fi
        fi
        
        ### installing dependencies
        # checking if homebrew is installed
        if [[ $(command -v brew) == "" ]]
        then
            echo "homebrew is not installed..."
            if [[ $(command -v pip) == "" ]]
            then
                sudo python -m ensurepip
                sudo easy_install pip
            else
                :
            fi
            PYTHON_VERSION='python'
            sudo pip install --upgrade pip
            sudo pip install -r /Applications/hosts_file_generator/requirements.txt
            # do not update internal apple site-packages to ensure compatibility
            #pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo pip install -U
        else
            echo "homebrew is installed..."
            # do not autoupdate homebrew
            export HOMEBREW_NO_AUTO_UPDATE=1
            # uninstalling python2 version from brew
            if [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep python@2) == '' ]]
            then
                :
            else
                sudo -u $(logname) brew uninstall --ignore-dependencies python@2
            fi
            # uninstalling other pip versions to avoid confusion of the update script
            if [[ $(command -v pip) == "" ]]
            then
                :
            else
                yes | sudo python -m pip uninstall pip
            fi
            # making sure python3 is installed
            if [[ $(command -v pip3) == "" ]]
            then
                if [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep python) == '' ]]
                then
                    sudo -u $(logname) brew install python
                else
                    sudo -u $(logname) brew reinstall python
                fi
            else
                :
            fi
            PYTHON_VERSION='python3'
            # updating pip itself
            sudo -u $(logname) pip3 install --upgrade pip
            # updating all pip modules
            pip3 freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -u $(logname) pip3 install -U
            # installing dependencies
            sudo -u $(logname) pip3 install -r /Applications/hosts_file_generator/requirements.txt
        fi
        
        # backing up original hosts file
        if [ ! -f /etc/hosts.orig ];
        then
            echo "backing up original hosts file..."
            sudo cp -a /etc/hosts /etc/hosts.orig
        else
            :
        fi
    
        # updating / creating hostsfile
        echo "updating hosts file..."
        cd /Applications/hosts_file_generator/
        #sudo python updateHostsFile.py -a -r -o alternates/gambling-porn-social -e gambling porn social
        sudo ${PYTHON_VERSION} updateHostsFile.py -a -r -o alternates/gambling-porn -e gambling porn
        #sudo python updateHostsFile.py -a -n -r -o alternates/gambling-porn-social -e gambling porn social
        #sudo python updateReadme.py
        cd -
    
        # comment out lines
        # sport1
        #sudo sed -i '' '/cdn-static.liverail.com/s/^/#/g' /etc/hosts
        #or
        #sudo awk -i inplace '/cdn-static.liverail.com/ {$0="#"$0}1' /etc/hosts
        #sudo sed -i '' '/c.amazon-adsystem.com/s/^/#/g' /etc/hosts
        sudo sed -i '' '/probe.yieldlab.net/s/^/#/g' /etc/hosts
        # anti-adblock popup
        sudo sed -i '' '/0.0.0.0 acdn.adnxs.com/s/^/#/g' /etc/hosts
        # spiegel.de
        sudo sed -i '' '/imagesrv.adition.com/s/^/#/g' /etc/hosts        
		# google shopping
        sudo sed -i '' '/www.googleadservices.com/s/^/#/g' /etc/hosts
        sudo sed -i '' '/0.0.0.0 ad.doubleclick.net/s/^/#/g' /etc/hosts
        sudo sed -i '' '/pagead.l.doubleclick.net/s/^/#/g' /etc/hosts
        
        # testing
        # open respective website in browser
        # deactivate adblocker for the website
        # open /etc/hosts in gas mask and add / delete entries
        #sudo killall -HUP mDNSResponder && sleep 2 && open -a /Applications/Firefox.app http://www.sport1.de

        # activating hosts file
        echo "activating hosts file..."
        # older osx versions
        #sudo dscacheutil -flushcache
        # newer macos versions
        sudo killall -HUP mDNSResponder
        
        # done
        echo 'done ;)'
    
    else
        echo "we are not not online, skipping update of hosts file... exiting script..."
    fi
    
}

(time hosts_file_install_update) 2>&1 | tee -a $LOGFILE

#sudo chmod 644 $LOGFILE
#sudo chmod 666 $LOGFILE

#(time hosts_file_install_update) 2>&1 | sudo tee -a $LOGFILE
# does not work, so the whole script has to be run as root or the privileges of the logfile have to be changed before and after running the script

fi
