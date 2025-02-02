macOS Scripting for Configuration, Backup and Restore
=============

Hey to every macOS user ;)

I am not a developer but an apple user and admin for more than 10 years. A clean install is generally a good way on every operating system to track down and avoid bugs. Additionally, old, no longer needed files in the system get deleted. Unfortunately, a clean install usually is time-consuming, especially when taking care of several devices.

Therefore I initiated this project: to make clean installations (including restoring some already configured files from previous installations) and macOS configurations as simple, customizable and fast as possible by providing a walkthrough of a clean macOS install including manuals, scripts, comments and a lot of macOS intel.

Furthermore I worked on some additional macOS scripts, e.g. [homebrew and cask updates](https://github.com/tiiiecherle/osx_install_config/tree/master/03_homebrew_casks_and_mas/3c_homebrew_formulae_and_casks_update), security and ad-blocking by [updating the hosts file](https://github.com/tiiiecherle/osx_install_config/tree/master/09_launchd/9b_run_on_boot/root/1_hosts_file) or [auto-selecting the network location](https://github.com/tiiiecherle/osx_install_config/tree/master/09_launchd/9b_run_on_boot/root/3_network_select) based on ethernet connectivity, [on demand and monitored virus scanning](https://github.com/tiiiecherle/osx_install_config/tree/master/09_launchd/9b_run_on_boot/root/4_clamav_monitor) using clamav - to mention just a few. These are not designed for a one-time configuration but for (automatic) regular usage after installation.

Of course, you can as well customize and run the commands and scripts on existing systems that did not lately get a clean install. All scripts and manuals are only optimized and updated for the latest available macOS and may or may not work on older versions.

One main goal (which started it all) is to make the complete macOS System Preferences highly customizable by script. Partially, existing scripts and code snippets were embedded. For these the [credit](#credits) goes to their authors. I ordered the content of [this script](https://github.com/tiiiecherle/osx_install_config/blob/master/11_system_and_app_preferences/11c_macos_preferences_mojave.sh) according to the macOS System Preferences and added configuration options for some default apple apps (Safari, Calendar, Contacts, ...).

Additionally I wrote a [backup and restore script](#7-backup-and-restore-script) for third party apps and their preferences files.

Initially this was intended for my personal use only. However I decided to publish everything here as it took me so many hours and I would have appreciated to find anything like this when I started. So, I hope it helps anyone ;)

Any help, feedback and comment for improvements and enhancements is welcome. There is a list of [preferences](#11-system-and-app-preferences) I couldn`t figure out to set by script until now, so I would appreciate help for solving them and also for testing the functionality of the scripts and commands. 

Read this ReadMe including the [disclaimer](#disclaimer) carefully before you start using anything and feel free to adjust every script and manual to your needs.

Happy installing, customizing and enjoying macOS ;)


Table of contents
-----

[Default shell and config file](#default-shell-and-config-file)  
[Usage](#usage)  
[0 Bootable usb device](#0bootable-usb-device)  
[1 NVRAM, system integrity protection and secure boot](#1nvram-system-integrity-protection-and-secure-boot)  
[2	Preparations](#2preparations)  
[3	Homebrew, Mas and Casks](#3homebrew-casks-and-mas)  
[4	SSD Optimizations](#4ssd-optimizations)  
[5	Network Configuration](#5network-configuration)  
[6	Manual app installation](#6manual-app-installation)  
[7	Backup and restore script](#7backup-and-restore-script)  
[8	Java 6](#8java-6)  
[9	Launchd](#9launchd)  
[10 Dock](#10-dock)  
[11 System and app Preferences](#11-system-and-app-preferences)  
[12 Licenses](#12-licenses)  
[13 Apple Mail and accounts](#13-apple-mail-and-accounts)  
[14 Samba](#14-samba)  
[15 Finalizations](#15-finalizations)  
[16 Seed update configuration](#16-seed-update-configuration)  
[Disclaimer](#disclaimer)  
[Credits](#credits)  


Default shell and config file
-----
In macOS 10.15 zsh replaces bash as default shell. I took the chance to rewrite and improve all scripts in many different aspects and functionality.

For optimization and easier maintenance I introduced a [config file](https://github.com/tiiiecherle/osx_install_config/blob/master/_config_file/shellscriptsrc.sh) that is installed to `~/.shellscriptrc` and is sourced before running a lot of the scripts. It includes an auto-update function. Make sure the versions of the script and the config file are always up-to-date and compatible.

The config file can be installed by using this command in the terminal:

`curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh`

From now on all scripts use zsh as default interpreter. At the time of the change (2019-07) all scripts are zsh and bash compatible, but further development is only being done for the default macOS shell, therefore zsh. Using bash instead of zsh can easily be achieved by using the bash shebang in the script.


Usage
-----
Download the complete github repository or single scripts, adjust everything to your needs and follow the instructions and manuals wherever needed. Some scripts depend on other scripts, so it is recommended to keep the directory structure and naming of files and folders. 

All `.sh` scripts, which have to be executable, contain additional information as comments and are meant to be run by opening a terminal and typing (or by drag & drop).

```
/path/to/name-of-script.sh
```

All `.txt` files contain information, manuals and comments. `.command` files are opened in a terminal by just double-clicking on them.

The steps to be taken are consecutively numbered and meant to be done in the given order to make them work correctly as some scripts or manuals depend on completed previous ones.

For easier maintenance most of the comments inside the scripts and manuals are not case sensitive and just written in small letters on purpose.

Before deleting everything on your drive and starting a clean macOS install make sure you have at least one working backup of all relevant files. I recommend doing one backup with [the backup script](#7-backup-and-restore-script) and another one on a second external device or partition using time machine.

As mentioned above some scripts (e.g. homebrew-update, hosts, network-select, etc.) come with installer scripts that copy the needed files to the respective locations in the system and adjust their ownership and permissions. They can be used on a regular basis (some of them automatically) after installation.

##### Batch Installation

After a lot of changes to the structure, the content, the config file and the default shell in the scripts it's finally possible (as of 2019-09, macOS 10.14 and newer) to combine most of them as a batch installer. After customizing and adjusting all scripts to your needs follow these steps:

0. Make a backup to an external drive/server/nas with the [backup script](#7backup-and-restore-script). Just to be safe I recommend an additional time machine backup.
0. Create the [bootable usb device](#0bootable-usb-device) and perform a clean macOS install.
0. Adjust the settings for [NVRAM, SIP and Secure Boot](#1nvram-system-integrity-protection-and-secure-boot).
0. Use the [batch install scripts](https://github.com/tiiiecherle/osx_install_config/blob/master/_batch_run/) and reboot in between.

This has the advantage that the scripts do not have to be run one by one. Instead the batch scripts sequentially processes all the scripts and play a sound when done. After each batch script check all outputs (and logfiles if needed) and reboot before starting the next one.

This makes the install/restore itself easy, mostly unattended, clean and fast.

0	Bootable usb device
-----

##### Preparation

Before starting with the clean install of macOS a bootable usb device is needed. This is how to create it.

0. Format usb drive with guid partition table in disc utility.
0. Create a new partition (at least 10 GB) and format the partition on the drive with macOS Extended (Journaled), name it "Untitled" and leave it mounted.
0. Download the macOS installer from the Mac App Store (usually downloads to /Applications/).
0. Adjust the installer name and path in the [script](https://github.com/tiiiecherle/osx_install_config/blob/master/00_bootable_usb_device/0b_create_bootable_usb_device.sh) and run it.

Steps 1 and 2 can be replaced by using [0a\_format\_bootable\_usb\_device.sh](https://github.com/tiiiecherle/osx_install_config/blob/master/00_bootable_usb_device/0a_format_bootable_usb_device.sh). It formats the complete usb device into two partitions (installer and data) and gives you the option to delete the efi partition afterwards. This makes the data partition on the usb device usable on a win10 pc.

##### Installation

To perform the actual clean installation, boot the mac from the created usb device by restarting and holding the `alt` key until the logo is displayed. 

Select the usb device installer as startup volume.

Inside the installer use disk utility to delete and format your drive with the file system of your choice. During this process I rename my drives to a label without whitespaces for easier terminal usage. That's why in all scripts of this project `macintosh_hd` is used as name for the main system partition of the newly installed macOS.


1	NVRAM, system integrity protection and secure boot
-----

##### NVRAM

Script 1a adjusts NVRAM parameters and therefore allows to manipulate firmware variables.


##### System Integrity Protection (SIP)

With macOS 11.10 El Capitan Apple introduced a new security feature named system integrity protection which prevents the user from getting root and thereby from making changes to specific system files and directories.

If you want to disable SIP (partially or completely) follow these steps. Before you do that make sure you know what you are doing.

##### Disable System Integrity Protection (partially or completely) in Recovery

0. Reboot your mac to recovery mode (hold down `command + R` during reboot)
0. Open Utilities
0. Open Terminal
0. `csrutil status`
0. `csrutil enable --without debug --without fs`
0. `csrutil status`
0. Reboot

If SIP is enabled `csrutil status` shows the status of every SIP component. It is possible to disable one single component while keeping SIP partially enabled, e.g.:

```
csrutil enable --no-internal
csrutil enable --without kext  
csrutil enable --without fs  
csrutil enable --without debug  
csrutil enable --without dtrace  
csrutil enable --without nvram
csrutil enable --without basesystem
```
or multiple components can be disabled, e.g. for these scripts to work use:  
`csrutil enable --without debug --without fs`

To disable SIP completely, use `csrutil disable`.  
To enable all components, use `csrutil enable`.  
To reset SIP to factory defaults use `csrutil clear`.

##### Disable Secure Boot in Recovery Mode

All Macs with T2 Chips, e.g. the MacBook Pro 2018 have an additional security feature which disables booting from external devices by default. To enable booting from external usb devices, follow these steps:

0. Reboot your mac to recovery mode (hold down `command + R` during reboot)
0. Open Utilities
0. Open Start-Up-Security-Utility
0. Set Secure Boot to whatever protection you like
0. Set External Boot to allow booting from external usb devices
0. Reboot

This can be reset for security reasons after finishing the installation.

2	Preparations
-----
##### macOS Updates
Script 2a updates macOS on the command line if the system should not be up to date. Script 2b is a short manual and checklist which contains a few steps that have to be done before continuing with the next steps.

##### zsh as default shell und customizations
[Install command line tools](https://github.com/tiiiecherle/osx_install_config/tree/master/02_preparations/2c_install_command_line_tools.sh) and [set zsh as default shell](https://github.com/tiiiecherle/osx_install_config/tree/master/02_preparations/2d_login_shell_customization.sh) incl. customizations with [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh).

3	Homebrew, Casks and Mas
-----
Homebrew is a really nice project and a package manager for macOS. In combination with homebrew cask it allows you to install and update command line software, players, plugins and apps on macOS on the command line.

Mas makes it possible to install and update apps from the macOS appstore using the command line.

You will find more information here:

* [homebrew](https://brew.sh)
* [homebrew-cask](https://formulae.brew.sh/cask)
* [mas-cli](https://github.com/mas-cli/mas)

[These scripts](https://github.com/tiiiecherle/osx_install_config/tree/master/03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install) install macOS Command Line Tools, homebrew, homebrew-cask and mas. Additionally, they take the entries from separate list files and install homebrew formulas, apps from the App Store, macOS-plugins and macOS-apps in parallel mode. It is like downloading and installing them manually but a lot faster and more comfortable. To easily keep all packages and apps up-to-date a [macOS-app Wrapper update script](https://github.com/tiiiecherle/osx_install_config/tree/master/03_homebrew_casks_and_mas/3c_homebrew_formulae_and_casks_update) is also included and can be installed to /Applications using the dmg installer.


4	SSD Optimizations
-----
Do not run this script if your volume is not an ssd.


5	Network Configuration
-----
To avoid network issues this script deletes `/Library/Preferences/SystemConfiguration/preferences.plist` and adds new locations, devices and preferences.

It can be run with profiles - to be easily usable on multiple macs - or standalone. More information can be found in the comments inside the script and in the example profile. To run the script with a profile, duplicate the example profile and name it `network_profile_USER.conf`. Change USER to your logged in macOS username.

To reset all network configurations and settings run the following commands in the terminal before running the script.

```
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.network.identification.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/preferences.plist
sudo reboot
```

6	Manual app installation
-----
This is just a checklist of apps to install manually if their installation is not possible by restoring or via homebrew cask.


7	Backup and restore script
-----
This backup/restore tool is highly customizable, configurable and based on well-known command line tools. It is working well for years with multiple backups and restores on different macs.

At first glance it seems a bit complicated but it really isn`t ;)

When running the script by double clicking the `run_backup_script.command` you will be asked to select a user if you have multiple users on your mac. Afterwards you will be prompted by an applescript to choose a directory where to save the backup. The backup files and folders will temporarily be saved to `~/Desktop/backup_$USER_DATE` and is supposed to preserve all file permissions. In the next step the script creates a .tar.gz.gpg file of the backup folder and checks the file integrity. After the test has passed successfully the temporary files on the Desktop get deleted. It uses your macOS password to encrypt the backup.

The lines in the `.../list/backup_restore_list.txt` specify the files and folders to be backed up or restored.

All lines that get backed up or restored start by u (user) and the script does a syntax check of the backup_restore_list.txt file at the beginning. Lines that are commented out are ignored and the echo lines will be displayed in the Terminal while running.

Over time the script gathered more and more backup options for different purposes, e.g. an applescript for backing up calendars, contacts and reminders using the GUI. 

To make usage for multiple users easier and faster it can be run with profiles. More information can be found in the comments inside the script and in the example profile. To run the script with a profile, duplicate the example profile and name it `backup_profile_USER.conf`. Change USER to your logged in macOS username.

##### restore

Make sure you only restore files and folders this way that were backed up with this script, so they have the correct structure inside the backup/restore directory. 

Select the folder containing the backup files when the script prompts for the respective input.

Use `run_restore_script.command` to restore.

##### general

At the end of the restore process the script also resets the permissions in the `/Applications` and `/Users/$USER` folder. If files or folders are added to the backup/restore list that are not in the User folder, make sure to add the permissions in the `.../permissions/ownerships_and_permissions_restore.sh` script for restore.

If there are any questions, feel free to ask. And, of course, any help to make this better and easier is always appreciated.


8	Java 6
-----
Not a lot of applications still use java 6 on macOS.

To make them work without installing apple java uncomment the options inside and run this script.

Before running the script download and install the latest version of java (jre) from [java.com](http://www.java.com) or [adoptopenjdk](https://adoptopenjdk.net). Alternatively install one of them through homebrew-cask.


9	launchd
-----

launchd is a unified operating system service management framework which starts, stops and manages daemons, applications, processes and scripts on macOS.

As it is sometimes very helpful to run scripts on boot (as root or user), at login or at logout, these scripts show how to do that. They come with installer scripts and are highly configurable.


##### AdBlocking by extensions and /etc/hosts (as root, on boot)

As Adblocking is important on the internet, this script combines adblockers and entries in the /etc/hosts file for best possible speed and adblocking results. It contains a manual for configuration and a script to install the /etc/hosts entries, as well as a launchd service that keeps it up to date on a given intervall. The script uses [this project](https://github.com/StevenBlack/hosts) to update the hosts file.


##### Local certificate check and installation (as root, on boot)

Even on a local network it is recommended to use SSL certificates to encrypt connections to other computers on the network. SSL certificates can’t be issued for auto-acceptance for local LAN connections and therefore they have to be accepted explicitly. If a certificate is issued by [letsencrypt](https://letsencrypt.org) it gets renewed on a regular basis. This script checks if the certificate was renewed and auto-adds it to the keychain to allow local LAN usage without re-accepting the certificate every time it is renewed.


##### Auto network selection (as root, on boot)
The [network configuration script](#5network-configuration) offers the possibility to add different locations, devices and settings to the network preferences.
If, for example, a MacBook is used via ethernet in combination with a static IP in the office and via wi-fi using dhcp in other locations, the network settings (location & wifi on/off) would have to be changed manually on every boot. This script checks if an ethernet cable is connected and selects the matching locations automatically.

##### Screen resolution (as user, on boot)

I use an external monitor in the office and (due to a bug) it gets reset to its default resolution on every reconnect of my MacBook Pro. This script only needs user privileges and uses [display manager](https://github.com/univ-of-utah-marriott-library-apple/display_manager) to check the desired resolution and applies it, if necessary.

##### Run commands at login or logout (as root)

macOS provides a possibility to add a script that is run at login or logout. This section contains the scripts to install them. Feel free to adjust them to your needs. In this version the logout script cleans some caches on a regular basis.


10 Dock
-----
This script completely cleans the dock and adds new entries including apps, spacer, folders or recent applications/documents to the dock. For folders and recent entries, it includes options for the icon size (grid only) and the type to be used (automatic, stack, grid or list).

It can be run with profiles - to be easily usable on multiple macs - or standalone. More information can be found in the comments inside the script and in the example profile. To run the script with a profile, duplicate the example profile and name it `dock_profile_USER.conf`. Change USER to your logged in macOS username.


11a System and app Preferences
-----
These are the main scripts described in the first section of this readme. They make it possible to adjust almost all of the macOS System Preferences and Apple Applications that are installed with the OS by default.

It’s important to start with 11a. Otherwise, some scripts of this section will not work, as it sets certain permissions for apps that are needed afterwards.


##### Unsolved Preferences

The following preferences are not yet configurable with the script. Any help to add the functionality is appreciated.

* preferences - control center - sorting order
* preferences - mac app store - download all bought apps on other macs automatically
* preferences - user & groups - applying login window accessibility settings without opening the dialog in system preferences

12 Licenses
-----
All bought third party apps have to get their licenses enabled after a clean install. A few can be done by restoring the correct files with the [restore script](#7-backup-and-restore-script), but unfortunately this is not working for all apps.

This is a checklist of licenses to be restored manually.


13 Apple Mail and Accounts
-----
In 10.11 apple moved all remaining internet accounts from

```
~/Library/Mail/V2/MailData/Accounts.plist 
to
~/Library/Accounts/Accounts3.sqlite
```

According to the version of macOS and Mail the script resets/deletes the index files to force Mail to reindex all mailboxes on its next run.


14 Samba
-----
macOS gives the user the possibility to set some options and preferences for its implemented samba client.

These options are documented in
`man nsmb.conf`

To make use of these options the script creates the configuration file
`~/Library/Preferences/nsmb.conf` and adds the entries referring to the macOS version (as the syntax of the file has changed).

For the fastest and most reliable connection in the current version it

* forces SMB3 connections  
* disables the requirement for signing
* deletes all other entries from nsmb.conf file.


15 Finalizations
-----
Despite all the automation, not everything in the process can be done by scripts yet. These files (for Apple apps and System Preferences) just give me a checklist of all preferences to be set manually. Every help to make this list shorter and add the settings to a script is welcome.

Additionally, there are two more scripts:

* disable Siri analytics
* hardening Firefox

At the end of every clean installation there are a few steps that take some cpu power and time before the mac is completely ready and usable at full speed, e.g. indexing emails after restore, full system virus scan, etc. These steps are documented in a checklist.


16 Seed update configuration
-----
There are a lot of beta and developer seed users of macOS out there. As I am a public beta user, too, I use macOS beta on a second partition for testing.

This manual tells you how to set/switch the update catalog.


Disclaimer
-----------

I am not responsible for any problems, damages, data loss or data corruption that may occur due to using any of this. Most of the commands are tested, but some might not be. There is always the chance that some things changed after the last usage/testing. So, use everything here completely at your own risk.

Do some research if you have any concerns about commands or procedures that are included in any of the files BEFORE using them. 


Credits
------------
[mathiasbynens](https://github.com/mathiasbynens/dotfiles/blob/master/.macos)

[joeyhoer](https://github.com/joeyhoer/starter)

[will-riley](https://github.com/will-riley/osx_prefs-10.8/blob/master/osx_set_dockapps.sh)

Thanks to everyone I got information from and that I forgot to credit. If someone feels left out just write me and I´ll add the credit.

Thanks to all developers and users that share their knowledge and provide so much (free) high quality software that is used in many of these scripts. This would not be possible without all of their efforts.

Last but not least thanks to Apple for developing an extraordinary operating system in macOS.
