Manuals and Scripts for backup / restore and clean OS X installation
=============

Hey to every OS X user ;)

I am not a developer but an apple user and admin for more than 10 years. I realized that a clean install on every major OS X update is the best way to avoid many bugs and get rid of old, no longer needed files in the system. But unfortunately every install took a lot of time and I have more than one mac to admin... That`s why I did this project: to make clean installations on OS X as easy, individual and fast as possible.

Of course you can customize and run the commands and scripts on existing systems that did not lately get a clean install, too.

It`s kind of a walkthrough of a clean OS X install with manuals, scripts, comments and a lot of OS X know how that I gathered.

I wrote a [backup and restore script](#7---backup-and-restore-script) for all my third party apps and their preferences files. But restoring old OS system files on a clean new OS install is not recommended.

That`s why one of the intentions is to make the complete OS X System Preferences highly customizable by script. There were already a lot of existing scripts. Those built the basis and the idea for mine. That's why a lot of [credit](#credits) goes to their authors. I tried to make their scripts more complete with a lot of my own additions and even tried making them better and clearer by giving them a structure according to the OS X System Preferences and the apple apps that ship with the OS (Safari, Calendar, Contacts, ...).

At first it was intented only for my personal use. But then I decided to publish everything here because it took me so many hours and I would have loved to find anything like this when I started. So I hope it helps anyone ;)

This said, any help, feedback and comment for making this better and even more complete is very welcome. There is a list of [stuff](#11a-unsolved-preferences) I couldn`t figure out, so it would be nice to have help for that and test all the functions and commands. 

Read this ReadMe including the [disclaimer](#disclaimer) carefully before you start using anything and feel free to adjust every script and manual to your needs.

Happy installing and customizing ;)


Table of contents
-----

[Usage](#usage)  
[0 Bootable usb device](#0---bootable-usb-device)  
[1 NVRAM and system integrity protection](#1---nvram-and-system-integrity-protection)  
[2	Network Configuration](#2---network-configuration)  
[3	Install AppStore apps and copy files](#3---install-appstore-apps-and-copy-files)  
[4	SSD Optimizations](#4---ssd-optimizations)  
[5	Homebrew and Casks](#5---homebrew-and-casks)  
[6	Manual app installation](#6---manual-app-installation)  
[7	Backup and restore script](#7---backup-and-restore-script)  
[8	Java 6](#8---java-6)  
[9	Unified Remote](#9---unified-remote)  
[10 Dock apps](#10-dock-apps)  
[11 OS X System and app Preferences](#11-os-x-system-and-app-preferences)  
[12 Licenses](#12-licenses)  
[13 Apple Mail and Accounts](#13-apple-mail-and-accounts)  
[14 Samba](#14-samba)  
[15 Manual Preferences](15-manual-preferences)  
[16 Restoring more files](#16-restoring-more-files)  
[17 Seed update configuration](#17-seed-update-configuration)  
[Disclaimer](#disclaimer)  
[Credits](#credits)  


Usage
-----
Just download all files, adjust everything to your needs and follow the instructions and manuals. All `.sh` script files contain additional information as comments and are ment to be run by opening a terminal and typing

```ruby
sh /path/to/name-of-script.sh
```

All `.rtf` files contain information, manuals and comments.

The files are numbered and ment to be used in this order because some scripts or manuals need tools or other stuff from one or more steps before.

And yes, it is intentional that all the content of the files is written in small letters for easier maintenance.

Before you delete everything on your drive and start a clean OS X install be sure you have at least one working backup of all relevant files.

I do so with [my backup script ](#7---backup-and-restore-script) and [backuplist+](http://rdutoit.home.comcast.net/~rdutoit/pub/robsoft/pages/softw.html).


0	Bootable usb device
-----
Before starting with a clean install of OS X a bootable usb device is needed. This is how you create it.

0. Format usb drive with guid partition table in disc utility.
0. Create a new partition (at least 10 GB) and format the partition on the drive with OS X Extended (Journaled), name it "Untitled" and leave it mounted.
0. Download the OS X installer to /Applications/.
0. Adjust the installer name and path in the script and run the script afterwards.

You will end up with a bootable usb device.

For the next step boot your mac from this created usb device by restarting and holding the `alt` key. 

Select the usb device as device to install from.

When formatting your drive be sure to select OS X Extended (Journaled) for best compatibility. I always rename my drives for easier use of the terminal with a name without spaces. So all scripts from me are using `macintosh_hd` as name for the main partition.


1	NVRAM and system integrity protection
-----
Script 1a adjusts NVRAM parameters. Adjust to your needs and run it.

With OS X 11.10 El Capitan Apple introduces a new security feature named system integrity protection which prevents you from getting root and making changes to the system.

As I want and need to do some changes to the system with the following scripts I switch it off. Before you do that make sure you know what you are doing.

If script 1b is not working (which is currently the case) do the following steps to disable system integrity protection manually.

0. Reboot your mac to recovery mode (reboot with command + R pressed).
0. Open utilities.
0. Open security configuration.
0. Disable enforce system integrity protection
0. Reboot


2	Network Configuration
-----
As there were a lot of problems lately with network configurations, especially wifi, this script deletes all locations and adds them in a new clean configuration file.

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
File 3a is a manual and checklist file which contains a few steps that have to be done to go on with the later scripts, e.g. installing Xcode and copying over your backup files for later restoring.

Script 3b opens Xcode.app to install the command line tools (components) that are needed for the next steps. Run it after installing Xcode.app or open XCode.app by double clicking on it in the /Applications folder.


4	SSD Optimizations
-----
Adjust to your needs and run it.
 
Do not run it if your volume is not an ssd.


5	Homebrew and Casks
-----
Homebrew is a really nice project and a package manager for OS X. In addition with homebrew cask it allows you to install and update software packages, players, plugins and apps on OS X.

You will find more information here:

* [homebrew](http://brew.sh)
* [homebrew cask](http://caskroom.io)

This script installs a few plugins and furthermore a few apps directly to the /Applications folder without linking them. It is like really installing them to this directory. The disadvantage is that homebrew cask does not know for versioning that those are already installed.

But this is not a big problem, just re run the script to update homebrew and all plugins, players and apps that are specified in it.

Adjust to your needs and run it. Be sure you have the XCode command line tools installed before running.

You have to enter your password a second time during the script when the first cask gets installed. If anyone knows how to avoid that help is much appreciated.


6	Manual app installation
-----
This is just a checklist of apps I have to install manually (besides the restore and the cask install).


7	Backup and restore script
-----
When I was looking for a highly configurable backup / restore tool I could not find one that was fitting my needs and working reliable. That`s why I wrote this script which is working very well for over a year (with multiple backups and restores and different macs) now.

At a first glance it seems a bit complicated but it isn`t ;)

There is the scritp itself and a bunch of `.txt` files where the files and folders for the backup are specified. The backup will be saved to `~/Desktop/backup_USERNAME_DATE` and is supposed to preserve all file permissions. That's why OS X could ask for your password when trying to delete the backup folder. I use .zip or .7z to store the backup to another volume without loosing file permissions. 

The first line in each `.txt` file specifies a directory. In the following lines (only one entry per line) the files and folders that are supposed to be backed up from this particular directory are listed. For example the content of the following `.txt` file backups the file `Bookmarks.plist` and the complete folder `Extensions` from the `~/Library/Safari` folder. Only the first line accepts subfolders and paths. You will need another `.txt` file for every directory containing files or folders you want to backup.

```ruby
~/Library/Safari
Bookmarks.plist
Extensions
```

The scripts uses all `.txt` documents in the two folders (master and user) automatically. So `.txt` files can be added, deleted and edited as long as the structure is preserved.

Here is why there is a master and a user folder. As I admin more than one mac that are not kept up to date every time with all apps and settings I splitted it up to a master and user backup. In the following I also split up the manual for single mac use and master / user implementation.

##### single / separate mac usage

If you only use one mac or a few macs that do not have files / folders that are kept up to date by a "master" or admin just put all `.txt` documents with your backup entries in the master folder and delete all `.txt` documents from the user folder, but keep the user folder itself. It will output an error in the end of the backup and the restore, but you can safely ignore that.

```ruby
head: *.txt: No such file or directory
is not a directory, skipping *.txt
```
Please only restore files and folders like this that were backed up with this script so they have the right structure. For a restore create the following directories on your desktop 

```ruby
mkdir -p ~/Desktop/restore/master
mkdir -p ~/Desktop/restore/user
```

and place all respective backup folders and files in the master directory, for example

```ruby
~/Desktop/restore/master/Applications
~/Desktop/restore/master/Library
~/Desktop/restore/master/Users
```

Then run the script to restore.

##### master / user usage

In this context it makes no difference for the backup, but when restoring all entries that exist in the master directory (apps and preferences that are equal on every of the macs and the master keeps them up to date during the year) are restored from the master backup and all user related files and folders from the user directory.

Please only restore files and folders like this that were backed up with this script so they have the right structure. For a restore create the following directories on your desktop

```ruby
mkdir -p ~/Desktop/restore/master
mkdir -p ~/Desktop/restore/user
```

and place all respective backup folders and files in the master directory, for example

```ruby
~/Desktop/restore/master/Applications
~/Desktop/restore/master/Library
~/Desktop/restore/master/Users
~/Desktop/restore/user/Applications
~/Desktop/restore/user/Library
~/Desktop/restore/user/Users
```

Then run the script to restore.

##### general

This gives you a highly configurable way to backup and restore only the files and folders you want.

Sounds more complicated than it is, if there are any questions feel free to ask me.

And of course any help to make this better and easier is appreciated here, too.


8	Java 6
-----
Some applications still use java 6 on OS X.

To make them work without installing apple java run this script.

Before running the script download and install the latest version of java jre from [java.com](http://www.java.com) or through homebrew cask.


9	Unified Remote
-----
I love to control my mac through my phone. There are multiple possibilities to do that. I very much like [Unified Remote](https://www.unifiedremote.com).

If you don`t use unified remote you can skip this script.

As I use static IPs and different locations with my macbook I need the unified remote server to restart for getting the right IP every time I change the location in the network preferences. I solved this by writing a script that monitors the change of network locations and restart the app. It is installed and used like this.

```ruby
1. Copy unified_remote_restart.scpt to
~/Library/Scripts/unified_remote_restart.scpt
2. change username in com.run_script_on_network_change.plist in program arguments and copy the file to 
~/Library/LaunchAgents/com.run_script_on_network_change.plist
Do not copy it to /Library/LaunchAgents/ or the app will not be restartable when quit through the script.
3. Run the script to enable the service.
```

10 Dock apps
-----
This script completely wipes your dock and adds new entries including apps and spacer to the dock.

Adjust to your needs and run it.


11 OS X System and app Preferences
-----
This is the main script described in the beginning of the readme that makes it possible to adjust almost all of the OS X System and app Preferences.

Adjust to your needs and run it.


11a Unsolved Preferences
-----------

The following preferences are not yet configurable with the script and any help to add the functionality is appreciated.

* mail: view mailboxes list in the sidebar
* defaults write commands for office 2011 and 2016
* preferences - general - number of recent documents/apps/servers
* preferences - language & region - first weekday
* preferences - language & region - calendar gregorian
* preferences - security - enable automatic login
* preferences - security - enable filevault
* preferences - control center - sorting order
* preferences - monitor - change resolutions
* preferences - keyboard - keyboard - show keyboard in menu bar
* preferences - sound - input - ambient noise reduction
* preferences - mac app store - download all bought apps on other macs automatically
* 

12 Licenses
-----
All bought third party apps have to get their licenses enabled. A few can be done by restoring the correct files with the [restore script](#7---backup-and-restore-script), but unfortunately not all of the ones I have.

This is a checklist of licenses that I have to activate again so I don`t forget one ;)


13 Apple Mail and Accounts
-----
In 10.11 apple moves all remaining internet accounts from

```ruby
~/Library/Mail/V2/MailData/Accounts.plist 
to
~/Library/Accounts/Accounts3.sqlite
```
If you are doing a clean install of 10.11 to update from 10.10 you need to run this script to update accounts and make them match with the restored mail data. Be careful, please follow these steps in this order to make it work.

* Run [restore script](#7---backup-and-restore-script) or copy your maildata to `~/Library/Mail/` manually.
* Delete all accounts. All internet accounts (including iCloud) from the System Preferences will be gone and OS X will start with a fresh `.sqlite` database.

```ruby
	rm /Users/tom/Library/Accounts/Accounts3.sqlite
	rm /Users/tom/Library/Accounts/Accounts3.sqlite-shm
	rm /Users/tom/Library/Accounts/Accounts3.sqlite-wal
	rm /Users/tom/Library/Preferences/MobileMeAccounts.plist
```
* Reboot.
* Run migrate accounts script.
* Delete all old and deactivated accounts in the System Preferences.
* Re-add iCloud accounts and activate sync.

```ruby
this list is just a personal example
	private
		calendars
		contacts
		reminders
		notes
	office
		calendars
		contacts
```

* Open mail for converting the data from V2 to V3 and check if everything works.
* Re-attach the default signatures in mail.
* Open calendar and contacts and check if everything works.
* Delete old mail folder.

```ruby
	rm -rf ~/Library/Mail/V2
```

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

In addition I had some trouble to configure some virtualbox machines for working internet connections in different locations on my macbook. This is why I added a file with the manual for a working configuration.


16 Restoring more files
-----
As this is a matter of personal taste I use the [backup script](#7---backup-and-restore-script) more for apps, mails and settings. For big folders with a lot of files I use [backuplist+](http://rdutoit.home.comcast.net/~rdutoit/pub/robsoft/pages/softw.html) to back them up. It`s now time to restore those files to their location and this is a checklist of those files. You can of course use my backup / restore script, too.


17 Seed update configuration
-----
There are a lot of beta and developer seed users of OS X out there. As I am a public beta user, too, I use OS X beta on a second partition for testing.

This manual tells you how to set the correct update catalog for the appstore and tells you how to download update files for saving them for later use.


Disclaimer
-----------

I am not responsible for any problems, damages, file loss or data corruption that may occure because of using any of this. Most of the commands are tested, but some (that I don`t use) are untested. So use everything here completely at your own risk.

Do some research if you have any concerns about commands or procedures that are included in any of the files BEFORE using them. 


Credits
------------
[mathiasbynens](https://github.com/mathiasbynens/dotfiles/blob/master/.osx)

[joeyhoer](https://github.com/joeyhoer/starter)

[will-riley](https://github.com/will-riley/osx_prefs-10.8/blob/master/osx_set_dockapps.sh)

Thanks to everyone I got information from and I forgot to credit. I did so much research and do not remember all websites. If someone feels left out just write me and I´ll add the credit.

