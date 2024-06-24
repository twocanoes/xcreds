# What's New In XCreds #

## XCreds 5.0 ##

Expected AD field values not shown in XCreds log #237
-------
keyCodeForLoginWindowChange not working as expected #231
"Change Password" menuitem is now greyed out #239
Allow user to use full name to sign in at XCreds username/password screen #178
Feature Request: HideExpiration key #198
XCreds 5: Unexpected behavior of IP & MAC info via XCReds login window #232
Menubar sign in does not follow shouldUseROPGForMenuLogin #184
improved login animation
Customize menu bar app icon #189
Update description for allowLoginIfMemberOfGroup #228
Add LocalFallback to manifest #229
Enhancement Request "Mechanism to force xCreds to reevaluate Login Window Background Image" #227
-----
[Feature Request] Add a Password Expire date or Days for OIDC users and more #165. To test, set map_password_expiry to a claim in Azure (like street address) with a value in seconds from token issue (like 300 seconds) and verify that menu shows the correct date
Custom Mac login window key combo #206
Enhancement request: Group Membership Zendesk Ticket 69193 #209
Setting HomeMountEnabled to false removes the home folder from the XCreds menuitems #213

----------
Map UID #186
Menubar refresh is delayed when setting shouldPromptForADPasswordChange #195
Fix formatting for systemInfoButtonTitle #221
Corrections for manifest #224
Hang at login after password reset #223
----------
Customize the XCReds app's native login dialog box #179
[Feature Request] AD User Account Creation Name Mapping #172
[Feature Request] AD - User friendly fail prompts #193
AD attributes #166
systemInfoButtonTitle does not respond to plain text values #220
Clarify key name an description for shouldShowIfLocalOnlyUser #219
changed manifest version back one; added copying DS user attibutes to prefs. Enhancement Request: XCreds app cant update ds #212
----------
[Feature Request] Add option to customize the Refresh Banner text #176
Feature Request: EnforceSignIn #199
added new preference to manage more buttons on login screen: shouldShowShutdownButton, shouldShowRestartButton, shouldShowSystemInfoButton. Feature Request - Add key to disable showing shutdown and/or restart on login overlay #203
Allow override of killall loginwindow in xcreds postinstall script #181
bumped version of manifest Update manifest pfm_last_modified and pfm_version #164
fixed Fix manifest title for ROPG pref #183
added option for system info button title #154
System Info on XCreds Login Window #154
implemented Feature Request - Change the wording of the password change pop-up #202

## XCreds 4.1 ##

Customization of Menu

Adding Menu Items

Cloud + Active Directory

SMB Share Mounting

Admin Removal


## XCreds 4.0 ##

Select Existing User Account During Account Creation

Allow Admin to Reset User Password at Login

Key Combination for Showing Standard and Mac Login Window

Account Alias

Saving Groups to Account Attributes

CreateAdminIfGroupMember Checked At Each Login

Add Arbitrary Claims to Local DS User Account

Refactored Preferences for ROPG

Allowed Users

Other New Features and Fixes



## XCreds 3.3 ##

### Select Existing User Account During Account Creation ###
Using the new preference key “shouldPromptForMigration”, when a new login is detected and there are existing standard user accounts on the system, the user will be prompted for a username and password (#98).

If the username and password are successfully entered for an existing account, this local account will then be used when logging in with this cloud account. The local account has 2 new DS attributes added:

dsAttrTypeNative:_xcreds_oidc_sub: Subscriber. Unique identifier for account within the current issuer. 

dsAttrTypeNative:_xcreds_oidc_iss: Issuer
In subsequent logins, the user account is selected by matching the sub and iss from the identity token to the values in the local account.

Note that the user will only be prompted if there are existing standard accounts on the system and the login does not have a locally mapped account.

The dialog for migration has a “Create New Account” button that will allow them to skip migration and create a local account. If a local account using the prior logic exists, it will be mapped.

### Key Combination for showing Standard and Mac login window ###
Setting the new preference key “shouldAllowKeyComboForMacLoginWindow” allows switch login between cloud and standard/Mac login using a key combination regardless of the hidden state of the Switch Login Window button (#121). The keys are as follows:

Option-Control-Return: Switch between cloud and standard login window.
Command-Option-Control-Return: Switch between cloud and Mac login window.

### Account Alias ###
When a new preference is set (“aliasName”) to a claim in the identity token, the value in that claim is used to set an alias to the user account, allowing them to login with it.

An example: Set the preferences to have aliasName = “upn”. Log in as barney@twocanoes.com. The identity token has a claim called “upn” whose value was “barney@twocanoes.com“. XCreds then adds barney@twocanoes.com that is an alias and the user can login with either barney or barney@twocanoes.com at the local and mac login window. This gives the user a consistent way to log in at the cloud login or the standard / Mac login window.

### New Features ###
* Removed logging messages that had a local path from the build system.
* Updates postinstall to better handle the setup assistant and userland install scenarios. Thanks to Clkw0rk for the pull request.
* Reload login window on network changes. Thanks to Clkw0rk for the pull request and credit to @hurricanehrndz and the CPE Team at Yelp
* Reload login window after wifi connected. Thanks to Clkw0rk for the pull request.
* add encoding for special characters to tokenmanager. Thanks to Clkw0rk for the pull request.
* use default desktop from CoreServices. Thanks to Clkw0rk and the CPE Team at Yelp for the pull request.


## XCreds 3.2 ##

* Support for Okta ROPG
* New preference key to force local login: shouldPreferLocalLoginInsteadOfCloudLogin
* New preference key show login window based on detecting network status: shouldDetectNetworkToDetermineLoginWindow
* Added self healing for auth rights
* Added support for keyboard nav for controls
* Detect offline and automatically switch to local login
* Remove trailing and leading spaces entered in username


## XCreds 3.1 ##

### Active Directory Login ###
New username and password window allows logging in with local user or Active Directory (if ADDomain key is defined).

### New Username and Password Window ###
We no longer use the macOS login window and use the new XCreds username/password window. This allows for faster switching and Active Directory login.

### Switch to Login Window at Screen Saver ###
When the "shouldSwitchToLoginWindowWhenLocked" key is set and XCreds is running in the user session and the screen is locked, the lock screen will fast user switch to the login window.

When set to true and the user locks the current session, XCreds will tell the system to switch to Login Window. The current session will stay active but the user will log in with the XCreds Login Window to resume the session.

### Admin Group ###

If group membership is returned in the "groups" claim and matches the group defined in the "CreateAdminIfGroupMember" preference, the user will be created as admin.

### kerberos ticket ###
When app is first launched and there is a keychain item with an AD account and local password, a kerberos ticket will be attempted.

### Override Preference Script ###

Most preferences can now be overwritten by specifying a script at the path defined by "settingsOverrideScriptPath". This script, if it exists, owned by \_securityagent, and has permissions 700 (accessible only by \_securityagent) must return a valid plist that defines the key/value pairs to override in preferences. This allows for basing preferences based on the local state of the machine. It is important for the "localAdminUserName" and "localAdminPassword" keys.  See Reset Keychain for more information on this. The override script can also be used for querying the local state and setting preferences. For example, to randomly set the background image, a sample script "settingsOverrideScriptPath" defines a script:


    #!/bin/sh
    dir="/System/Library/Desktop Pictures"
    desktoppicture=`/bin/ls -1 "$dir"/*.heic | sort --random-sort | head -1`
        
    cat /usr/local/xcreds/override.plist|sed "s|DESKTOPPICTUREPATH|${desktoppicture}|g" 
    
The plist would be defined as:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>loginWindowBackgroundImageURL</key>
        <string>file://DESKTOPPICTUREPATH</string>
    </dict>
    </plist>


### Reset Keychain ##
In prior versions of XCreds, the ability to reset the keychain if the user forgets their local password would fail due to the lack of an admin user with a secure token. This would cause the "PasswordOverwriteSilent" to fail. 

The "settingsOverrideScriptPath" (see above) can return the admin username and password of an admin account that has a secure token. This admin user is then used to reset the user's keychain if they forgot their local password. This can either be done with user prompting or silently.

The script can find those keys via curl, in system keychain, or in a LAPS file and return the values inside the plist that is returned. This gives flexibility in determining the security required for the local admin username and password.

Note that XCreds assumes an admin user with a secure token already exists on the machine and XCreds does not create or manage this user. If you manage local admin via a LAPS system, you can return the password from the local password file.

An example of an override script to return username and password are as follows:

Override Script:

   ` #!/bin/sh`
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
* added dialog over login window when in an error state
* improved code when local password policy does not allow setting password from cloud.
* Added about menu with history

## New Keys

**ADDomain**

The desired AD domain

**usernamePlaceholder**

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

Username of local admin user. DO NOT SET THIS IN PREFERENCES. It is recommended to set this with the settingsOverrideScriptPath script. This user is used to reset the keychain if the user forgets their local password and to set up a secure token for newly created users.

**localAdminPassword**

Password of local admin user. DO NOT SET THIS IN PREFERENCES. It is recommended to set this with the settingsOverrideScriptPath script. This user is used to reset the keychain if the user forgets their local password and to set up a secure token for newly created users.

**shouldShowCloudLoginByDefault**

Determine if the Mac login window or the cloud login window is shown by default

**shouldShowMacLoginButton**

Show the Mac Login Window button in XCreds Login

**shouldShowTokenUpdateStatus**
Show the time when the password will be checked. True by default.

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
