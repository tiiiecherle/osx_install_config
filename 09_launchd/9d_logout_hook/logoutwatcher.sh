#!/bin/bash

onLogout() {
    # Insert whatever script you need to run at logout
    function quit_whatsapp() {
    osascript 2>/dev/null <<EOF
#osascript <<EOF
try
	
	# taking actions on changing network locations
	
	# setting variables
	set appname2 to "WhatsApp"
	
	# waiting for the system to apply network location name
	delay 1
		
	### app2	
	if application appname2 is running then
		tell application "System Events"
			set ProcessList to name of every process
			if appname2 is in ProcessList then
				set ThePID to unix id of process appname2
				do shell script "kill -KILL " & ThePID
			end if
		end tell		
	end if
	
on error
	---
end try
EOF
}
    quit_whatsapp
    
    touch /Users/tom/Desktop/logout.txt
    
    exit
}

#sudo touch /var/log/org.my.log
#sudo echo "INFO - Watching ${HOME}" >> /var/log/org.my.log

touch /Users/tom/Desktop/login.txt

trap 'onLogout' SIGINT SIGHUP SIGTERM

while true; do
    sleep 86400 &
    wait $!
done