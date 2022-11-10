#!/bin/bash -e

if [ ! -d "/Library/LaunchAgents" ]; then
	mkdir /Library/LaunchAgents
fi

if [ -e "/Library/LaunchAgents/local.xcreds.plist" ]; then
	echo "/Library/LaunchAgents/local.xcreds.plist already exists. exiting."
else
	/usr/libexec/PlistBuddy -c "Add :Label string local.xcreds" /Library/LaunchAgents/local.xcreds.plist
	/usr/libexec/PlistBuddy -c "Add :ProgramArguments array" /Library/LaunchAgents/local.xcreds.plist
	/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string /Applications/XCreds.app/Contents/MacOS/XCreds" /Library/LaunchAgents/local.xcreds.plist
	/usr/libexec/PlistBuddy -c "Add :KeepAlive bool YES" /Library/LaunchAgents/local.xcreds.plist

	echo "successfully set up xcreds to launch at login for every user."
fi 
