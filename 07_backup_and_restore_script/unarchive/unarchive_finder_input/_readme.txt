decrypt and unarchive gpg apps

0	homebrew and needed tools have to be installed
	brew install gnutar coreutils pv gnupg2


1	apps itself are automator workflows that run applescripts
	open the .app files with automator to edit them


2	set icon
	a	open terminal
		PATH_TO/icon_set_python3.py PATH_TO/gpgtools.icns PATH_TO/APPNAME.app
	b	right click on APPNAME.app
		show package content - Contents - Resources
		copy icon.icns to .../Resources/applet.icns
	c	show package content - Contents - Info.plist with texteditor
		<string>CFBundleIconFile</string>
		<key>AutomatorApplet</key>
		# neither special chracters nore _ or - are supported in the filename.icns 

3	set document icon for associated files

	!	.icns has to have a special format

	a	right click on APPNAME.app
		show package content - Contents - Resources
		copy document.icns to .../Resources/document.icns
	b	show package content - Contents - Info.plist with texteditor
		add 
		<key>CFBundleTypeIconFile</key>
		<string>document.icns</string>
		to <key>CFBundleDocumentTypes</key>
		# neither special chracters nore _ or - are supported in the document.icns 
	c	clear icon cache
		sudo rm -rfv /Library/Caches/com.apple.iconservices.store; sudo find /private/var/folders/ \( -name com.apple.dock.iconcache -or -name com.apple.iconservices \) -exec rm -rfv {} \; ; sleep 3;sudo touch /Applications/* ; killall Dock; killall Finder


4	associate filetype for open with dialog
	show package content - Contents - Info.plist with texteditor
	<key>CFBundleTypeExtensions</key>
	<array>
		<string>gpg</string>
	</array>	


5	set bundle identifyer
	show package content - Contents - Info.plist with texteditor
	<key>CFBundleIdentifier</key>
	<string>com.apple.automator.decrypt_finder_input_gpg_progress</string>
	<key>CFBundleName</key>
	<string>decrypt_finder_input_gpg_progress</string>

6	set default open with
	click in .gpg file
	cmd +i
	default open with
	choose decrypt_finder_input_gpg_progress.app
	use for all
	# or use script to set