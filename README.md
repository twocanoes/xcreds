# XCreds: Sync Your Cloud Password to your Mac

## How It Works
XCreds has 2 components: the XCreds app that runs in user space and XCreds Login Window that is a security agent that runs when the user is logging in to their mac. Both the security agent and the app share keychain items in the user's keychain to key track of the current local password and the tokens from the cloud provider. Both items prompt the user withe a web view to authenticate to their cloud provider, verify log in was successful and then updates the local password and user keychain passwords as needed. 

## Requirements
XCreds currently works with Azure and Google cloud as an OIDC identity provider. It has been testing on macOS Monterey but should support earlier version of macOS.

## Components
XCreds consists of XCreds Login and XCreds app. They do similar tasks but run at different times. 

### XCreds Login
XCreds Login is a Security Agent that replaces the login window on macOS to provide authentication to the cloud provider. It presents a web view at the login window and fully supports multi-factor authentication. When authentication completes, the web view receives Open Id Connect (OIDC) tokens and stores those tokens in the login keychain. If the local password and the cloud password are different, the local password is updated to match the cloud password and the login keychain password is updated a well. The local password is then stored in the user keychain so that any password changes in the future can be updated silently. Only the security agent and the XCreds app are given permission to access the password and tokens.

### XCreds App
The XCreds app runs when the user logs in. On first launch, it checks to see if xcreds tokens as available in the login keychain. If they are, the refresh token is used to see if it is still valid. If it is invalid (due to a remote password change), the user is prompted with a web view to authenticate with their cloud credentials. If they authenticate successfully, the tokens are updated in the login keychain and the password is check to see if it has been changed. If it changed, the local account and login keychain is updated to match the cloud password. 

## Configuration
Configuration and setting is handled from a config profile. See the Preferences section below for details on each key. The discovery URL and client ID values are required. All others are optional. 

We recommend you use a preference manifest and use [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) with the  [supplied manifest](https://github.com/twocanoes/xcreds/releases).

A sample configuration profile is [available to download](https://github.com/twocanoes/xcreds/releases) as well.


## Azure Setup
See the [wiki](https://github.com/twocanoes/xcreds/wiki) for Azure instructions

## Google Cloud Setup
See the [wiki](https://github.com/twocanoes/xcreds/wiki) for Azure instructions


# Download
Download XCreds from the [github release page](https://github.com/twocanoes/xcreds/releases)

# Setup
To get started with XCreds, follow the instructions below. All resources are within the app itself and setup is configured using command line tools inside the app bundle. Preferences are handled by configuration profiles (see below).

1. Install the XCreds package. This will install XCreds.app into your application folder and does not install any other items.

1. Install a configuration profile by follow the instructions below under the Preferences section. 

1. Launch the app by double clicking on it. A new menu item will appear with chasing arrows. A web view will also appear since there are no xcreds tokens in the keychain. Authenticate with your cloud password. You will be prompted for your local password and your local password and keychain password will be updated if it is different from your cloud password.

1. In order to activate XCreds Login, open terminal and run:

    `sudo /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -i`
    
    This will install a XCreds security agent called "XCredsLoginPlugin.bundle" in /Library/Security/SecurityAgentPlugins and a launch daemon called "com.twocanoes.xcreds-overlay.plist" in /Library/LaunchDaemons. The launch daemon shows an overlay on the standard login window to return back to XCreds Login. The authorizationdb is also updated to activate the Security Agent and you can see the new rules by running:
    
    `security authorizationdb read system.login.console`
    
	A backup copy of the replaced rules is stored in /Library/Application Support/xcreds/rights.bak.  
	
1. Log out of the mac. The XCreds login window will be presented. Log in with your cloud credentials.

1. XCreds.app will not launch automatically. You can use Login Items in System Preferences to automatically launch XCreds.app or use a MDM policy.

## Uninstall
1. 	To remove XCreds Login, restore the backup security agent rules and remove the launch agent, run:
	
	`sudo /Applications/XCreds.app/Contents/Resources/xcreds_login.sh -r`

1. Drag the XCreds app to the trash.


## Preferences
The easiest way configure is to use [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) using the [supplied manifest](https://github.com/twocanoes/xcreds/releases). The following keys can then be set and managed:

*discoveryURL* (string): The discovery URL provided by your OIDC / Cloud provider. For google it is typically "https://accounts.google.com/.well-known/openid-configuration" and for Azure it is typically "https://login.microsoftonline.com/common/.well-known/openid-configuration"

*scopes* (string): Scopes tell the identify provider what information to return. Note that the values are provided with a single space between then. 

    Provide the following values the follow IdPs:

	    Google: profile openid email
	    Azure: profile openid offline_access

    Note that Google does not support the offline_access scope and instead the preference "shouldSetGoogleAccessTypeToOffline" preference. Azure provides "unique_name" which is mapped to the local user account by using the prefix before "@" in unique_name and matching to the short name of a user account. Google provides "email" and is matched in the same way. 
    


*redirectURI* (string): the URI passed back to the webview after successful authentication. Default value: "xcreds://auth/"
    
*refreshRateHours* (string): The number of hours between checks. Default value: "3".

*showDebug* (bool): Show push notifications for authentication progress. Default value: false

*verifyPassword* (bool): When cloud password is changed and the local keychain password and local user account needs to be changed, a verification dialog can be shown to verify the password. Default value: true

*LogFileName* (string): The name of the log file in ~/Library/Logs/. Default value: "xcreds.log"

*shouldShowQuitMenu* (bool): Show Quit in the menu item menu. Default value: true

*shouldShowAboutMenu* (bool): Show the About Menu item menu. Default value: true

*shouldShowPreferencesOnStart* (bool): Show Settings on start if none are defined. Default value: false

*username* (bool): When a user uses cloud login, XCreds will try and figure out the local username based on the email or other data returned for the IdP. Use this value to force the local username for any cloud login. Provide only the shortname.

*passwordChangeURL* (string): Add a menu item for changing the password that will open this URL when the menu item is selected.


## Video
See the [video on youtube](https://youtu.be/6V5MCQNWVTE)

## Support
Please join the #xcreds MacAdmins slack channel for any questions you have. Paid support is [available from Twocanoes Software](https://twocanoes.com/products/mac/xcreds/).

## Thanks

Special thanks to North Carolina State University and Everette Allen for supporting this project.

OIDCLite is Copyright (c) 2022 Joel Rennich (https://gitlab.com/Mactroll/OIDCLite) under MIT License.

XCreds is licensed under BSD Open Source License.


