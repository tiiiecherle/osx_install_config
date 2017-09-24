macOS Scripting for Configuration, Backup and Restore
=============

Hey to every macOS user ;)

I am not a developer but an apple user and admin for more than 10 years. I realized that a clean install on every major macOS update is the best way to avoid many bugs and get rid of old, no longer needed files in the system. But unfortunately every install took a lot of time and I have more than one mac to admin... That`s why I started this project: to make clean installations and macOS configurations as easy, individual and fast as possible.

Of course you can customize and run the commands and scripts on existing systems that did not lately get a clean install, too.

It`s kind of a walkthrough of a clean macOS install with manuals, scripts, comments and a lot of macOS know how that I gathered.

I wrote a [backup and restore script](#7-backup-and-restore-script) for all my third party apps and their preferences files. But restoring old OS system files on a clean new OS install is not recommended.

That`s why one of the intentions is to make the complete macOS System Preferences highly customizable by script. There were already a lot of existing scripts and some of them were integrated or influenced this project. That's why a lot of [credit](#credits) goes to their authors. I tried to make the scripts more complete with a lot of my own additions and even tried making them better and clearer by giving them a structure according to the macOS System Preferences and the apple apps that ship with the OS (Safari, Calendar, Contacts, ...).

At first it was intented for my personal use only. But then I decided to publish everything here because it took me so many hours and I would have loved to find anything like this when I started. So I hope it helps anyone ;)

This said, any help, feedback and comment for making this better and even more complete is very welcome. There is a list of [stuff](#11a-unsolved-preferences) I couldn`t figure out, so it would be nice to have help for solving them and testing all the functions and commands. 

Read this ReadMe including the [disclaimer](#disclaimer) carefully before you start using anything and feel free to adjust every script and manual to your needs.

Happy installing and customizing ;)


Table of contents
-----

[Usage](#usage)  
[0 Bootable usb device](#0-bootable-usb-device)  
[1 NVRAM and system integrity protection](#1-nvram-and-system-integrity-protection)  
[2	Network Configuration](#2-network-configuration)  
[3	Install AppStore apps and copy files](#3-install-appstore-apps-and-copy-files)  
[4	SSD Optimizations](#4-ssd-optimizations)  
[5	Homebrew and Casks](#5-homebrew-and-casks)  
[6	Manual app installation](#6-manual-app-installation)  
[7	Backup and restore script](#7-backup-and-restore-script)  
[8	Java 6](#8-java-6)  
[9	launchd](#9-launchd)  
[10 Dock apps](#10-dock-apps)  
[11 System and app Preferences](#11-system-and-app-preferences)  
[12 Licenses](#12-licenses)  
[13 Apple Mail and Accounts](#13-apple-mail-and-accounts)  
[14 Samba](#14-samba)  
[15 Manual Preferences](#15-manual-preferences)  
[16 Seed update configuration](#16-seed-update-configuration)  
[Disclaimer](#disclaimer)  
[Credits](#credits)  


Usage
-----
Just download all files, adjust everything to your needs and follow the instructions and manuals. All `.sh` script files contain additional information as comments and are ment to be run by opening a terminal and typing

```ruby
/path/to/name-of-script.sh
```

All `.txt` files contain information, manuals and comments.

The files are numbered and ment to be used in this order because some scripts or manuals depend on other ones ment to be run before.

And yes, it is intentional that all the content of the files is written in small letters for easier maintenance.

Before you delete everything on your drive and start a clean macOS install be sure you have at least one working backup of all relevant files.

I do so with [my backup script ](#7-backup-and-restore-script) and additionally I do a time machine backup just in case.


0	Bootable usb device
-----
Before starting with a clean install of macOS a bootable usb device is needed. This is how you create it.

0. Format usb drive with guid partition table in disc utility.
0. Create a new partition (at least 10 GB) and format the partition on the drive with macOS Extended (Journaled), name it "Untitled" and leave it mounted.
0. Download the macOS installer to /Applications/.
0. Adjust the installer name and path in the script and run the script afterwards.

You will end up with a bootable usb device.

For the next step boot your mac from this created usb device by restarting and holding the `alt` key. 

Select the usb device as device to install from.

When formatting your drive be sure to select macOS Extended (Journaled) for best compatibility. I always rename my drives for easier use of the terminal with a name without spaces. So all scripts from me are using `macintosh_hd` as name for the main partition of the installed macOS.


1	NVRAM and system integrity protection
-----
Script 1a adjusts NVRAM parameters. Adjust to your needs and run it.

With macOS 11.10 El Capitan Apple introduces a new security feature named system integrity protection which prevents you from getting root and making changes to the system.

As I want and need to do some changes to the system with the following scripts I switch it off. Before you do that make sure you know what you are doing.

As of now the system integrity protection has to be deactivated manually in the recovery.

##### Terminal

0. Reboot your mac to recovery mode (reboot with command + R pressed).
0. Open Utilities.
0. Open Terminal.
0. `csrutil status`
0. `csrutil disable`
0. `csrutil status`
0. Reboot

To re-enable it, reboot to recovery and type `csrutil enable`.

2	Network Configuration
-----
As there were a lot of problems in earlier macOS versions with network configurations, especially wifi, this script deletes all locations and adds them in a new clean configuration file.

Adjust to your needs and run it.

If you want to reset your complete network configuration run the following commands in the terminal before running the script.

```ruby
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.network.identification.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
sudo rm -rf /Library/Preferences/SystemConfiguration/preferences.plist
sudo reboot
```

3	Install AppStore apps and copy files
-----
File 3a is a manual and checklist file which contains a few steps that have to be done to go on with the later scripts, e.g. installing Xcode or Command Line Tools and copying over your backup files for restoring them later.


4	SSD Optimizations
-----
Adjust to your needs and run it.
 
Do not run it if your volume is not an ssd.


5	Homebrew and Casks
-----
Homebrew is a really nice project and a package manager for macOS. In addition with homebrew cask it allows you to install and update software packages, players, plugins and apps on macOS.

You will find more information here:

* [homebrew](http://brew.sh)
* [homebrew cask](http://caskroom.io)

This script installs a few plugins and furthermore a few apps directly to the /Applications folder without linking them. It is like downloading and installing them to this directory manually but a lot more comfortable and very easy for keeping everything up-to-date.

Adjust to your needs and run it. Be sure you have the Command Line Tools installed before running. If you don`t the skript will intall them for you.


6	Manual app installation
-----
This is just a checklist of apps I have to install manually (besides the restore and the cask install).


7	Backup and restore script
-----
When I was looking for a highly configurable backup / restore tool I could not find one that was fitting my needs and was working reliable. That`s why I wrote this script which is working very well for over three years (with multiple backups and restores and different macs) now.

At a first glance it seems a bit complicated but it really isn`t ;)

When running the script by double clilcking the `run_script.command` fiel you will be prompted by an applescript to choose a directory where to save the backup. In the meanwhile the backup will temporary be done in `~/Desktop/backup_USERNAME_DATE` and is supposed to preserve all file permissions. That's why macOS probably aska for your password when trying to delete the backup folder. In the next step the script creates a .tar.gz file of the backup folder (also on the Desktop) and checks the file integrity. When the check is passed successfully the file will be moved to the specified location and the temporary files on the Desktop will be deleted.

The lines in the `.../list/backup_restore_list.txt` specify the files and folders to be backed up or restored.

All lines that get backed up or restored start by an m (master) or u (user) and the script does a syntax check of the file at the beginning. Commented lines are ignored and the echo lines will be displayed in the Terminal while running.

Here is why there is a master and a user folder. As I admin more than one mac that are not kept up to date every time with all apps and settings. That`s why I splitted it up to a master and user restore. Everything that is marked as master will be restored from my backup, all entries marked as user will be restored from the user backup of the same mac.

##### restore

Please only restore files and folders this way that were backed up with this script so they have the right structure. For a restore create the following directories on your desktop 

```ruby
mkdir -p ~/Desktop/restore/master
mkdir -p ~/Desktop/restore/user
```

and make sure all respective backup folders and files are in the directories, for example

```ruby
~/Desktop/restore/master/Applications
~/Desktop/restore/master/Library
~/Desktop/restore/master/Users
```

If you do not use a master / user structure and only backup / restore one and the same mac just select the same folder for master und user when the script prompts for the missing folder.

Then run the script to restore.

##### general

This gives you a highly configurable way to backup and restore only the files and folders you want.

It also resets and takes care of the permissions in the `/Applications` and `/Users/$USER` folder. If you add files or folders to your backup / restore list that are not in the User folder make sure to add the permissions in the `.../permissions/ownerships_and_permissions_restore.sh` script for restore.

Sounds more complicated than it is, if there are any questions feel free to ask me.

And of course any help to make this better and easier is appreciated here, too.


8	Java 6
-----
Some applications still use java 6 on macOS.

To make them work without installing apple java run this script.

Before running the script download and install the latest version of java jre from [java.com](http://www.java.com) or through homebrew cask.


9	launchd
-----

##### run on network change

As I use a MacBook Pro I change network locations very often. Some services and apps require a restart after that to work. This launchd service keeps looking for changing the network config and performs some operations in this case.

Here it restarts the Whatsapp Desktop app. 

```ruby
1. copy to 
	/Users/$USER/Library/Scripts/run_on_network_change_login.app
	/Users/$USER/Library/Scripts/run_on_network_change.app
	chmod 755 /Users/$USER/Library/Scripts/run_on_network_change_login.app
	chmod 755 /Users/$USER/Library/Scripts/run_on_network_change.app
2. change username in com.run_script_on_network_change.plist in program arguments and copy the file to 
	~/Library/LaunchAgents/com.run_script_on_network_change.plist
	chmod 644 ~/Library/LaunchAgents/com.run_script_on_network_change.plist
	Do not copy it to /Library/LaunchAgents/ or the app will not be restartable when quit through the script.
3. Run the script to enable the service.
```

##### AdBlocking by extensions and /etc/hosts

As Adblocking is a big thing in the internet I had a closer look and found a good combination of speed and adblocking by combining adblockers and entries in the /etc/hosts file. It contains a manual for configuration and a script to install the /etc/hosts entries and a launchd service that keeps it up to date.


10 Dock apps
-----
This script completely wipes your dock and adds new entries including apps and spacer to the dock.

Adjust to your needs and run it.


11 System and app Preferences
-----
These are the main scripts described in the beginning of the readme that makes it possible to adjust almost all of the macOS System and app Preferences.

Adjust to your needs and run them. Start with 11a or some parts of the rest will not work as it activates applescript gui-scripting by the terminal.


11b Unsolved Preferences
-----------

The following preferences are not yet configurable with the script and any help to add the functionality is appreciated.

* mail: view mailboxes list in the sidebar
* preferences - language & region - first weekday
* preferences - language & region - calendar gregorian
* preferences - control center - sorting order
* preferences - monitor - change resolutions
* preferences - keyboard - keyboard - show keyboard in menu bar
* preferences - sound - input - ambient noise reduction
* preferences - mac app store - download all bought apps on other macs automatically

12 Licenses
-----
All bought third party apps have to get their licenses enabled. A few can be done by restoring the correct files with the [restore script](#7-backup-and-restore-script), but unfortunately not all of the ones I have.

This is a checklist of licenses that I have to activate again so I don`t forget one ;)


13 Apple Mail and Accounts
-----
In 10.11 apple moves all remaining internet accounts from

```ruby
~/Library/Mail/V2/MailData/Accounts.plist 
to
~/Library/Accounts/Accounts3.sqlite
```

Please read the manual files in the folder for further instructions and run the script after the required steps.


14 Samba
-----
SMB3 is way faster than SMB2. If you use apples default configuration the mac always searches for the best connection what is way slower than forcing SMB3 connections. And this is exactly what this script does. It creates a file (if it does not already exist)

```ruby
~/Library/Preferences/nsmb.conf
```
and puts the needed entries in it. All other entries in the file will be deleted. So do a backup of your file or adjust the script before you run it.


15 Manual Preferences
-----
Despite all the automation, not everything can be done by the scripts yet. Those files (for apple apps and system preferences) just give me a checklist of all preferences to be set manually. Every help to make this list shorter and add the settings to a script is welcome.


16 Seed update configuration
-----
There are a lot of beta and developer seed users of macOS out there. As I am a public beta user, too, I use macOS beta on a second partition for testing.

This manual tells you how to set the correct update catalog for the appstore and tells you how to download update files for saving them for later use.


Disclaimer
-----------

I am not responsible for any problems, damages, file loss or data corruption that may occure because of using any of this. Most of the commands are tested, but some are not or maybe some things changed after my last use. So use everything here completely at your own risk.

Do some research if you have any concerns about commands or procedures that are included in any of the files BEFORE using them. 


Credits
------------
[mathiasbynens](https://github.com/mathiasbynens/dotfiles/blob/master/.macos)

[joeyhoer](https://github.com/joeyhoer/starter)

[will-riley](https://github.com/will-riley/osx_prefs-10.8/blob/master/osx_set_dockapps.sh)

Thanks to everyone I got information from and I forgot to credit. I did so much research and do not remember all websites. If someone feels left out just write me and I´ll add the credit.

