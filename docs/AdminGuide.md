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

We recommend you use a preference manifest and use [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) with the  [supplied manifest](../releases).

A sample configuration profile is [available to download](../releases) as well.


## Azure Setup
See the [wiki](XCreds-Setup-with-Azure-OIDC) for Azure setup instructions

## Google Cloud Setup
See the [wiki](XCreds-Setup-with-Google-OIDC) for Google setup instructions


# Download
Download XCreds from the [github release page](../releases)

# Setup
To get started with XCreds, follow the instructions below. All resources are within the app itself and setup is configured using command line tools inside the app bundle. Preferences are handled by configuration profiles (see below).

1. Install the XCreds package. This will install XCreds.app into your application folder and does not install any other items.

1. Install a configuration profile by follow the instructions below under the Preferences section. 

1. Launch the app by double clicking on it. A new menu item will appear with chasing arrows. A web view will also appear since there are no xcreds tokens in the keychain. Authenticate with your cloud password. You will be prompted for your local password and your local password and keychain password will be updated if it is different from your cloud password.

1. XCreds Login is automatically activated when installed. The installer runs this command:

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
The easiest way configure is to use [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) using the [supplied manifest](../releases). The following keys can then be set and managed:

### discoveryURL ###
*discoveryURL* (string): The discovery URL provided by your OIDC / Cloud provider. For google it is typically "https://accounts.google.com/.well-known/openid-configuration" and for Azure it is typically "https://login.microsoftonline.com/common/.well-known/openid-configuration"

### clientID ###
*clientID* (string): The OIDC client id public identifier for the app.

### clientSecret ###
*clientSecret* (string): Client Secret sometimes required by identity provider.

### CreateAdminUser ###
*CreateAdminUser* (bool):  When set to true and the user account is created, the user will be a local admin.

### EnableFDE ###
*EnableFDE* (bool): Enabled FDE enabled at first login on APFS disks.

### EnableFDERecoveryKey ###
*EnableFDERecoveryKey* (bool): Save the Personal Recovery Key (PRK) to disk for the MDM Escrow Service to collect

### EnableFDERecoveryKeyPath ###
*EnableFDERecoveryKeyPath* (string): Specify a custom path for the recovery key

### EnableFDERekey ###
*EnableFDERekey* (bool): Rotate the Personal Recovery Key (PRK)

### scopes ###
*scopes* (string): Scopes tell the identify provider what information to return. Note that the values are provided with a single space between then. 

    Provide the following values the follow IdPs:

	    Google: profile openid email
	    Azure: profile openid offline_access

    Note that Google does not support the offline_access scope and instead the preference "shouldSetGoogleAccessTypeToOffline" preference. Azure provides "unique_name" which is mapped to the local user account by using the prefix before "@" in unique_name and matching to the short name of a user account. Google provides "email" and is matched in the same way. 
    

### shouldSetGoogleAccessTypeToOffline ###
*shouldSetGoogleAccessTypeToOffline* (bool): When using Google IdP, a refresh token may need be requested in a non-standard way.

### shouldShowCloudLoginByDefault ###
*shouldShowCloudLoginByDefault* (bool): When not set or set to true, show cloud login. If false, shows mac login.

### shouldShowConfigureWifiButton ###
*shouldShowConfigureWifiButton* (bool): Show Configure WiFi button in XCreds Login.

### shouldShowMacLoginButton ###
*shouldShowMacLoginButton* (bool): Show the Mac Login Window button in XCreds Login.

### shouldShowSupportStatus ###
*shouldShowSupportStatus* (bool): Show message in XCreds Login reminding people to buy support.

### shouldShowQuitMenu ###
*shouldShowQuitMenu* (bool): Show Quit Menu Item in the menu.

### shouldShowVersionInfo ###
*shouldShowVersionInfo* (bool): Show the version number and build number in the lower left corner of XCreds Login.

### redirectURI ###
*redirectURI* (string): the URI passed back to the webview after successful authentication. Default value: "xcreds://auth/"
    
### refreshRateHours ###
*refreshRateHours* (integer): The number of hours between checks. Default value: 3. Minimum value: 1. Max value: 168.

### showDebug ###
*showDebug* (bool): Show push notifications for authentication progress. Default value: false

### verifyPassword ###
*verifyPassword* (bool): When cloud password is changed and the local keychain password and local user account needs to be changed, a verification dialog can be shown to verify the password. Default value: true

### loginWindowBackgroundImageURL ###
*loginWindowBackgroundImageURL* (string): url to an image to show in the background while logging in.Default value file:///System/Library/Desktop Pictures/Monterey Graphic.heic.

### shouldShowQuitMenu ###
*shouldShowQuitMenu* (bool): Show Quit in the menu item menu. Default value: true

### shouldShowAboutMenu ###
*shouldShowAboutMenu* (bool): Show the About Menu item menu. Default value: true

### shouldShowPreferencesOnStart ###
*shouldShowPreferencesOnStart* (bool): Show Settings on start if none are defined. Default value: false

### username ###
*username* (string): When a user uses cloud login, XCreds will try and figure out the local username based on the email or other data returned for the IdP. Use this value to force the local username for any cloud login. Provide only the shortname.

### passwordChangeURL ###
*passwordChangeURL* (string): Add a menu item for changing the password that will open this URL when the menu item is selected.

### idpHostName ###
*idpHostName* (string): hostname of the page that has the password field. When the user submits the form, XCreds will use idpHostName to identify a page it needs to look for the password field. The password value is identified by a html id defined by passwordElementID. If this value is not defined. XCreds will look for login.microsoftonline.com and accounts.google.com. This value is commonly set for other IdP's and for Azure environments that use ADFS.

### map_firstname ###
*map_firstname* (string): Local DS to OIDC Mapping for First Name. Default value: "given_name". map_firstname should be set to an OIDC claim for first name.

### map_lastname ###
*map_lastname* (string): Local DS to OIDC Mapping for Last Name. Default value: "family_name". map_lastname should be set to an OIDC claim for last name.

### map_fullname ###
*map_fullname* (string): Local DS to OIDC Mapping for Full Name. Default value: "name". map_fullname should be set to an OIDC claim for full name.

### map_username ###
*map_username* (string): Local DS to OIDC Mapping for Name. Default value: "name". map_username should be set to an OIDC claim for name.

### passwordElementID ###
*passwordElementID* (string): password element id of the html element that has the password. It is read by using javascript to get the value (for example, for azure, the javascript 'document.getElementById('i0118').value' is sent. If this default is not set, standard values for Azure and Google Cloud will be used. To find out this value, use a browser to inspect the source of the page that has the password on it. Find the id of the textfield that has the password. Fill in the password and then open the javascript console. Run:

`document.getElementById('passwordID').value`

changing "passwordID" to the correct element ID. If the value to you typed into the textfield is returned, this is the correct ID.


## Video
See the [video on youtube](https://youtu.be/6V5MCQNWVTE)

## Support
Please join the #xcreds MacAdmins slack channel for any questions you have. Paid support is [available from Twocanoes Software](https://twocanoes.com/products/mac/xcreds/).

## Thanks

Special thanks to North Carolina State University and Everette Allen for supporting this project.

OIDCLite is Copyright (c) 2022 Joel Rennich (https://gitlab.com/Mactroll/OIDCLite) under MIT License.

XCreds is licensed under BSD Open Source License.


