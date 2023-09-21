#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### variables
###

HOMEBREW_PATH=$(brew --prefix)
HOMEBREW_BIN_PATH=""$HOMEBREW_PATH"/bin"
CUSTOM_SCAN_PROFILE=""$HOMEBREW_PATH"/etc/clamav/clamd_custom.conf"
FILE_LIST_SCAN="/tmp/clamav_scan_list.txt"
CLAMD_QUARANTINE_DIR="/Users/"$USER"/Desktop/clamav_scan_quarantine"
LOCAL_SOCKET=""$HOMEBREW_PATH"/var/run/clamav/clamd.sock"



###
### clamav scan
###

#printf "\033c"
printf "\ec"

echo ''
echo "${bold_text}clamav scan...${default_text}"

trap_function_exit_middle() { unset DIRECTORY_TO_SCAN; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"



### installation/update
echo ''
echo "${bold_text}formula installation...${default_text}"

for FORMULA in clamav gnu-tar gnu-sed
do
	if command -v "$FORMULA" &> /dev/null
	then
	    # installed
	    echo ""$FORMULA" is already installed..."
	else
		# not installed
		if command -v brew &> /dev/null
		then
		    # installed
		    if [[ $(brew list --formula | grep "^$FORMULA$") == "" ]]
		    then
			    #echo ''
				echo "installing missing dependency "$FORMULA"..."
				brew install "$FORMULA"
			else
				echo ""$FORMULA" is already installed..."
			fi
		else
			# not installed
			echo ''
			echo "homebrew is not installed, exiting..."
			echo ''
			exit
		fi
	fi
done

# clamav configuration
#echo ''
echo "clamav configuration..."

if [[ -e "$HOMEBREW_PATH"/etc/clamav/freshclam.conf ]]
then
	# configured
	:
else
	# not configured
	cp -a "$HOMEBREW_PATH"/etc/clamav/freshclam.conf.sample "$HOMEBREW_PATH"/etc/clamav/freshclam.conf
	sed -i '' 's/^Example/#Example/g' "$HOMEBREW_PATH"/etc/clamav/freshclam.conf
	cp -a "$HOMEBREW_PATH"/etc/clamav/clamd.conf.sample "$HOMEBREW_PATH"/etc/clamav/clamd.conf
	sed -i '' 's/^Example/#Example/g' "$HOMEBREW_PATH"/etc/clamav/clamd.conf
	touch "$CUSTOM_SCAN_PROFILE"
	chown "$USER":admin "$CUSTOM_SCAN_PROFILE"
	chmod 644 "$CUSTOM_SCAN_PROFILE"
	FRESH_INSTALL="yes"
fi

# make sure socket directory exists
mkdir -p "$HOMEBREW_PATH"/var/run/clamav
chown "$USER":admin "$HOMEBREW_PATH"/var/run/clamav
chmod 755 "$HOMEBREW_PATH"/var/run/clamav

# custom config file
cat > "$CUSTOM_SCAN_PROFILE" << EOF
LogTime yes
TemporaryDirectory /tmp
LocalSocket $LOCAL_SOCKET
User clamav
MaxDirectoryRecursion 50
MaxRecursion 50
MaxScanSize 0
MaxFileSize 0
MaxFiles 0
BytecodeTimeout 30000
EOF

# unofficial sigs
# https://github.com/extremeshok/clamav-unofficial-sigs
# https://github.com/extremeshok/clamav-unofficial-sigs/blob/master/guides/macosx.md
echo ''
echo "${bold_text}unofficial sigs installation...${default_text}"

if [[ -e ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh" ]]
then
	# installed
	echo "clamav-unofficial-sigs.sh is already installed, upgrading..."
	# root would be needed here, but the installation is completely homebrew and root free
	#clamav-unofficial-sigs.sh --upgrade
	#FRESH_INSTALL="yes"
else
	# not installed
	echo "installing clamav-unofficial-sigs.sh..."
	FRESH_INSTALL="yes"
fi

DOWNLOAD_FILE=clamav-unofficial-sigs.sh
curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/"$DOWNLOAD_FILE" --output ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh"
if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, exiting..." && exit; fi
chmod 755  ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh"
mkdir -p "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs
DOWNLOAD_FILE=master.conf
curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/"$DOWNLOAD_FILE" --output "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/master.conf
if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, exiting..." && exit; fi
DOWNLOAD_FILE=os.macos.conf
curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/"$DOWNLOAD_FILE" --output "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf
if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, exiting..." && exit; fi
DOWNLOAD_FILE=user.conf
curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/"$DOWNLOAD_FILE" --output "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/user.conf
if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, exiting..." && exit; fi

# configuration
echo "unofficial sigs configuration..."
mkdir -p ""$HOMEBREW_PATH"/var/homebrew/linked/clamav/share/clamav"
chown "$USER":admin ""$HOMEBREW_PATH"/var/homebrew/linked/clamav/share/clamav"
chmod 755 ""$HOMEBREW_PATH"/var/homebrew/linked/clamav/share/clamav"
sed -i '' 's|^clam_dbs=.*|clam_dbs="'"$HOMEBREW_PATH"'/var/homebrew/linked/clamav/share/clamav"|g' "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf
sed -i '' 's|^work_dir=.*|work_dir="'"$HOMEBREW_PATH"'/var/db/clamav-unofficial-sigs"|g' "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf
sed -i '' 's|^log_file_path=.*|log_file_path="'"$HOMEBREW_PATH"'/var/log"|g' "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf

# workaround for issue
# https://github.com/extremeshok/clamav-unofficial-sigs/issues/417
sed -i '' 's|^if \[ \-f \"\/etc\/clamav-unofficial-sigs\/master.conf\" \] \; then$|if \[ -f "'"$HOMEBREW_PATH"'\/etc\/clamav-unofficial-sigs\/master.conf\" \] \; then|g' "$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh
sed -i '' 's|^  config_dir\=\"\/etc\/clamav-unofficial-sigs\"$|  config_dir\="'"$HOMEBREW_PATH"'\/etc\/clamav-unofficial-sigs\"|g' "$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh
sed -i '' '/#\ clamscan_bin/a \
clamscan_bin="'"$HOMEBREW_PATH"'\/bin/clamscan"\
' "$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh

# fixing LinuxMalwareDetect Database File Updates
# tar: Option --wildcards is not supported
# Clamscan reports LinuxMalwareDetect rfxn.ndb database integrity tested BAD
if command -v gtar &> /dev/null
then
	# installed
	sed -i '' 's/command -v tar/command -v gtar/g' ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh"
else
	# not installed
	:
fi


# update (done later)
#clamav-unofficial-sigs.sh --force
#clamav-unofficial-sigs.sh


### sigs update
echo ''
echo "${bold_text}updating official definitions...${default_text}"
freshclam

echo ''
echo "${bold_text}updating unofficial definitions...${default_text}"
# does not write output to logfile
#clamav-unofficial-sigs.sh --force
#script -aqec "clamav-unofficial-sigs.sh"
if [[ "$FRESH_INSTALL" == "yes" ]]
then
	clamav-unofficial-sigs.sh --force
else
	clamscan_bin="/opt/homebrew/bin/clamscan" clamav-unofficial-sigs.sh
fi


### scanning
mkdir -p "$CLAMD_QUARANTINE_DIR"
find "$DIRECTORY_TO_SCAN" -type f > "$FILE_LIST_SCAN"
NUMBER_OF_FILES_TO_SCAN=$(cat "$FILE_LIST_SCAN" | wc -l | sed 's/^[ \t]*//;s/[ \t]*$//')
NUMBER_OF_FILES_TO_SCAN_FORMATTED=$(printf "$NUMBER_OF_FILES_TO_SCAN" | awk '{ len=length($0); res=""; for (i=0;i<=len;i++) { res=substr($0,len-i+1,1) res; if (i > 0 && i < len && i % 3 == 0) { res = "." res } }; print res }')

# starting clamd
echo ''
echo "${bold_text}starting clamd...${default_text}"

if [[ $(pgrep "clamd") == "" ]]
then
	clamd --config-file="$CUSTOM_SCAN_PROFILE" &
	# waiting for clamd to start
	while [[ $(pgrep "clamd") == "" ]] || [[ ! -e "$LOCAL_SOCKET" ]]
	do
	    sleep 1
	done
	sleep 10
else
	echo "clamd is already running..."
fi

# starting scan
echo ''
echo "${bold_text}scanning "$DIRECTORY_TO_SCAN"...${default_text}"
echo ''
# clamd scan (multi core)
clamdscan --multiscan --fdpass --allmatch --move="$CLAMD_QUARANTINE_DIR" --config-file="$CUSTOM_SCAN_PROFILE" "$DIRECTORY_TO_SCAN"

# or (single core)
#clamscan --max-files=15000 --max-scansize=4000M --max-filesize=4000M --max-recursion=50 --suppress-ok-results --allmatch --file-list=/tmp/clamav_scan_list.txt --move="$CLAMD_QUARANTINE_DIR"

# do not kill clamd, could be in use, e.g. in combination with fswatch
# if not used by another script or service it will not start on the next reboot
#sleep 2
#killall -15 clamd

echo "Files Scanned: "$NUMBER_OF_FILES_TO_SCAN_FORMATTED""


### done
open "$SCRIPT_DIR"/clamav_scan_done.app

echo ''
echo "done ;)"
echo ''


### documentation
### uninstall
uninstalling() {
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
brew uninstall clamav
rm -rf ""$BREW_PATH_PREFIX"/etc/clamav"
rm -rf ""$BREW_PATH_PREFIX"/bin/clamav-unofficial-sigs.sh"
rm -rf ""$BREW_PATH_PREFIX"/var/db/clamav-unofficial-sigs"
rm -rf ""$BREW_PATH_PREFIX"/var/run/clamav"
rm -rf ""$BREW_PATH_PREFIX"/opt/clamav"
rm -rf ""$BREW_PATH_PREFIX"/etc/clamav-unofficial-sigs"
rm -rf ""$BREW_PATH_PREFIX"/var/log/clamav-unofficial-sigs.log"
#dscl . list /Users UniqueID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
#dscl . list /Groups PrimaryGroupID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
#sudo -v
#sudo find /Volumes/macintosh_hd -type d -name "*clamav*"
#sudo dscl . delete /Users/_clamav
#sudo dscl . delete /Groups/_clamav
#sudo dscl . delete /Users/clamav
#sudo dscl . delete /Groups/clamav
}
#uninstalling

re-add_user() {
dscl . list /Users UniqueID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
dscl . list /Groups PrimaryGroupID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
sudo dscl . create /Groups/clamav
sudo dscl . create /Groups/clamav RealName "clamav"
sudo dscl . create /Groups/clamav gid 82           # Ensure this is unique!
sudo dscl . create /Users/clamav
sudo dscl . create /Users/clamav RealName "clamav"
sudo dscl . create /Users/clamav UserShell /bin/false
sudo dscl . create /Users/clamav UniqueID 82       # Ensure this is unique!
sudo dscl . create /Users/clamav PrimaryGroupID 82 # Must match the above gid!
}
#re-add_user