# XCreds: Sync Your Cloud Password to your Mac

## Overview
XCreds works by keeping your local Mac password in sync with your Identity Provider password. If you use Azure or Google or other identity provider, XCreds will make sure the password is the same. XCreds runs in the background and checks if the cloud password has been changed. If it detects the password has changed, it prompts to login to the cloud provider and updates the local password and the keychain password automatically.

## Configuration
Configuration and setting is handled from a config profile. See the Preferences section below for details on each key. The discovery URL and client ID values are required. All others are optional. 

We recommend you use a preference manifest and use [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) with the  [supplied manifest](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/com.twocanoes.xcreds.plist).

A sample configuration profile is available to download as well.



## Azure Setup
See the [wiki](https://github.com/twocanoes/xcreds/wiki) for Azure instructions

# Download
Download XCreds from the [github release page](https://github.com/twocanoes/xcreds/releases)


## How it works
XCreds is a menu item macOS application that works like this:

1. On first launch, it prompts the user for their local macOS password and saves it to the keychain where the app can retrieve it later. The password is verified to be correct against local directory services.

1. The user is prompted via a webview to log into their cloud provider. 

1. Once authenticated, OAuth tokens are returned verifying the authentication succeeded. These tokens are saved to the keychain. 

1. The cloud password entered is then used to set the local password and change the login keychain password.

## Preferences
The easiest way configure is to use [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) using the [supplied manifest](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/com.twocanoes.xcreds.plist). The following keys can then be set and managed:

*redirectURI* (string): the URI passed back to the webview after successful authentication. Default value: "xcreds://auth/"

*refreshRateHours* (string): The number of hours between checks. Default value: "3".

*showDebug* (bool): Show push notifications for authentication progress. Default value: false

*verifyPassword* (bool): When cloud password is changed and the local keychain password and local user account needs to be changed, a verification dialog can be shown to verify the password. Default value: true

*LogFileName* (string): The name of the log file in ~/Library/Logs/. Default value: "xcreds.log"

*shouldShowQuit* (bool): Show Quit in the menu item menu. Default value: true

*shouldShowPreferencesOnStart* (bool): Show Settings on start if none are defined. Default value: true


## Video
<iframe width="560" height="315" src="https://www.youtube.com/embed/6V5MCQNWVTE" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Support
Please join the #xcreds MacAdmins slack channel for any questions you have. Paid support is available from Twocanoes Software. 

## Thanks

Special thanks to North Carolina State University and Everette Allen for supporting this project.

OIDCLite is Copyright (c) 2022 Joel Rennich (https://gitlab.com/Mactroll/OIDCLite) under MIT License.

XCreds is licensed under BSD Open Source License.


