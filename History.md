# What's New In XCreds #

## XCreds 3.1 ##

### Active Directory Login ###
New username and password window allows logging in with local user or Active Directory (if ADDomain key is defined).

### New Username and Password Window ###
We no longer use the macOS login window and use the new XCreds username/password window. This allows for faster switching and Active Directory login.

### Switch to Login Window at Screen Saver ###
When the "shouldSwitchToLoginWindowWhenLocked" key is set and XCreds is running in the user session and the screen is locked, the lock screen will fast user switch to the log 

When set to true and the user locks the current session, XCreds will tell the system to switch to Login Window. The current session will stay active but the user will login with the XCreds Login Window to resume the session.

### Admin Group ###

If group membership is returned in the "groups" claim and matches the group defined in the "CreateAdminIfGroupMember" preference, the user will be created as admin.

### kerberos ticket ###
When app is first launched and there is a keychain item with a AD account and local password, a kerberos ticket will be attempted.

### Override Preference Script ###

Most preferences can now be overwritten by specifying a script at the path defined by "settingsOverrideScriptPath". This script, if it exists, owned by root, and has permissions 755 (writable only by root, readable and executable by all) must return a valid plist that defines the key/value pairs to override in preferences. This allows for basing preferences based on the local state of the machine. It is important for the "localAdminUserName" and "localAdminPassword" keys.  See Reset Keychain for more information on this. The overide script can also be used for querying the local state and setting preferences. For example, to randomly set the background image, a sample script "settingsOverrideScriptPath" defines a script:


    !/bin/sh
    dir="/System/Library/Desktop Pictures"
    desktoppicture=`/bin/ls -1 "$dir"/*.heic | sort --random-sort | head -1`
        
    cat /usr/local/xcreds/override.plist|sed "s|DESKTOPPICTUREPATH|${desktoppicture}|g" 
    
The plist would defined as:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>loginWindowBackgroundImageURL</key>
        <string>file://DESKTOPPICTUREPATH</string>
    </dict>
    </plist>


### Reset Keychain ##
In prior versions of XCreds, the ability to reset the keychain if the user forgets their local password would fail due to the lack of a admin user with a secure token. This would cause the "PasswordOverwriteSilent" to fail. 

The "settingsOverrideScriptPath" (see above) can return the admin username and password of an admin account that has a secure token. This admin user is then used to reset the user's keychain if they forgot their local password. This can either be done with user prompting or silently.

The script can find those keys via curl, in system keychain, or in a LAPS file and return the values inside the plist that is returned. This gives flexablity in determining the security required for the local admin username and password.

Note that XCreds assumes an admin user with a secure token already exists on the machine and XCreds does not create or manage this user. If you manage local admin via a LAPS system, you can return the password from the local password file.

An example of an override script to return username and password are as follows:

Override Script:

   ` !/bin/sh`
`    dir="/System/Library/Desktop Pictures"`
`    desktoppicture=/bin/ls -1 "$dir"/*.heic | sort --random-sort | head -1`
`    `
`    #this is provided as an example. DO NOT KEEP ADMIN CREDENTIALS ON DISK! Use curl or other method for getting them temporarily.`
`    admin_username="tcadmin"`
`    admin_password="twocanoes"`
`    `
`    cat /usr/local/xcreds/override.plist | sed "s|LOCALADMINUSERNAME|${admin_username}|g" | sed "s|LOCALADMINPASSWORD|${admin_password}|g" `

plist:

    `<?xml version="1.0" encoding="UTF-8"?>`
`    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">`
`    <plist version="1.0">`
`    <dict>`
`        <key>localAdminUserName</key>`
`        <string>LOCALADMINUSERNAME</string>`
`        <key>localAdminPassword</key>`
`        <string>LOCALADMINPASSWORD</string>`
`    </dict>`
`    </plist>`


### Others
* added shake to password field

## New Keys

**ADDomain**

The desired AD domain

**usernamePlaceholder*

Placeholder text in local / AD login window for username

**passwordPlaceholder**

Placeholder text in local / AD login window for password

**shouldShowLocalOnlyCheckbox**

Show the local only checkbox on the local login page


**CreateAdminIfGroupMember**

List of groups that should have its members created as local administrators. Set as an Array of Strings of the group name.

**shouldSwitchToLoginWindowWhenLocked**

When set to true and the user locks the current session, XCreds will tell the system to switch to Login Window. The current session will stay active but the user will login with the XCreds Login Window to resume the session.

**settingsOverrideScriptPath**

Script to override defaults. Must return valid property list with specified defaults. Script must exist at path, be owned by root and only writable by root.

**localAdminUserName**

Username of local admin user. DO NOT SET THIS IN PREFERENCES. It is recommended to set this with the settingsOverrideScriptPath script. This user is used to reset the keychain if the user forgets their local password and to setup a secure token for newly created users.

**localAdminPassword**

Password of local admin user. DO NOT SET THIS IN PREFERENCES. It is recommended to set this with the settingsOverrideScriptPath script. This user is used to reset the keychain if the user forgets their local password and to setup a secure token for newly created users.

**shouldShowCloudLoginByDefault**

Determine if the mac login window or the cloud login window is shown by default

**shouldShowMacLoginButton**

Show the Mac Login Window button in XCreds Login


## Version 3.0 Build 3607 ##

Released 2023-04-19

- Updated license
- Fixed typo
- Fixed issue with crash if time is too far off
- Fixed regression for password change not capturing new password on Azure
- Added trial license
- Version 2.4
- Added 802.1x support; added support for pref key for finding password based on type=password
- Fixed changing wifi not dismissing dialog
- Fixed issue with autorefresh
- Added frontmost when prompting for keychain password
- Fixed crashing issue due to null refreshview outlet
- Fixed names and links in manifest
- Tweaked text for user space refresh token window and added pref to show or hide
- Updated sample config
- Fixed focus issue
- Fixed login window size and background image
- Added in login window height/width min value of 100
- Added key for customizing return to XCreds; added preference and ability to automatically refresh login window
- Updated language on keychain option and added pref in manifest
- Added remove keychain option

## Version 2.3
- Added more logging for id token
- Removed progress screen overlay because it was hiding filevault
- Added sub as local user account if other methods not available; added some additional logging
- Removed test time
- Fixed edge case when not showing xcreds login when logging out
- Fixed shouldShowCloudLoginByDefault not working
- Fixed timer issue
- Removed show prefs menu
- Implemented PasswordOverwriteSilent
- Implemented KeychainReset
- Added credit to script
- Added startup script
- Username hint was not being set
- Renamed mapped prefs with a prefix
- Changed case of keys
- Made keys lowercase for mappings
- Added new key for OIDC mapping

## Version 2.2
- Added mappings for user info

## Version 2.1
- Initial release
