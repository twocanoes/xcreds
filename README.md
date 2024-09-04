# XCreds: Sync Your Cloud Password to your Mac

## How It Works
XCreds has 2 components: the XCreds app that runs in user space and XCreds Login Window that is a security agent that runs when the user is logging in to their mac. Both the security agent and the app share keychain items in the user's keychain to key track of the current local password and the tokens from the cloud provider. Both items prompt the user withe a web view to authenticate to their cloud provider, verify log in was successful and then updates the local password and user keychain passwords as needed. 

## Requirements
XCreds currently works with Azure and Google cloud as an OIDC identity provider. It has been tested on macOS Monterey but should support earlier version of macOS.

## Components
XCreds consists of XCreds Login and XCreds app. They do similar tasks but run at different times. 

### XCreds Login
XCreds Login is a Security Agent that replaces the login window on macOS to provide authentication to the cloud provider. It presents a web view at the login window and fully supports multi-factor authentication. When authentication completes, the web view receives Open Id Connect (OIDC) tokens and stores those tokens in the login keychain. If the local password and the cloud password are different, the local password is updated to match the cloud password and the login keychain password is updated a well. The local password is then stored in the user keychain so that any password changes in the future can be updated silently. Only the security agent and the XCreds app are given permission to access the password and tokens.

### XCreds App
The XCreds app runs when the user logs in. On first launch, it checks to see if xcreds tokens as available in the login keychain. If they are, the refresh token is used to see if it is still valid. If it is invalid (due to a remote password change), the user is prompted with a web view to authenticate with their cloud credentials. If they authenticate successfully, the tokens are updated in the login keychain and the password is check to see if it has been changed. If it changed, the local account and login keychain is updated to match the cloud password. 

## Setup and Configuration

See the [admin guide](https://github.com/twocanoes/xcreds/wiki/AdminGuide) on the wiki.

## Video
See the [video on youtube](https://www.youtube.com/watch?v=qtPy5ddp9kg&list=PLFtGGT240LAMYGcueZT76BySBQRFCzdce)

## Support
Please join the #xcreds MacAdmins slack channel for any questions you have. 

## Thanks

Special thanks to North Carolina State University and Everette Allen for supporting this project.

OIDCLite is Copyright (c) 2022 Joel Rennich (https://gitlab.com/Mactroll/OIDCLite) under MIT License.

XCreds is licensed under BSD Open Source License.


