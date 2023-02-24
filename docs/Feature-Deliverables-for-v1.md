# Feature Deliverables for v1
 
## Feature 1: macOS menu item app with option to sign in

Description: Provide a menu item for user to select options to login and sync.
Success Criteria: Menu item appears in status menu with icon and displays option for Sign In shown when menu item selected
 
## Feature 2: Application Settings

Description: A group of settings that define the needed attributes for logging into Azure IdP. Applicable settings set via configuration profile that can be used with MDM or installed locally.
Success Criteria: Configuration profile that, when installed, provides preferences viewable by the defaults command.
 
## Feature 3: OIDC Azure authentication

Description: Authenticate to Azure to obtain the authentication token and the user password.
Success Criteria: When sign-in selected in menu item, web view is presented to authenticate to Azure via OIDC. Demonstrate that the user password and the azure token is obtained via logging or display to the user.
 
## Feature 4: Credential Storage

Description: Provide secure storage for sensitive information such as Azure authentication tokens.
Success Criteria: Open keychain and view saved Azure authentication tokens.
 
## Feature 5: Password Syncing

Description: On a set schedule, verify that user password matches the password Azure password. If the password is different, prompt the user to authenticate. After authentication, the local user account password is set to the Azure password and the authentication token is updated in the keychain.
Success Criteria: By viewing the logs or other means of status, verify that check is one on the configured schedule. If user is not logged in or password is different, verify that web view is shown for authentication. Verify password is updated after authentication.
 
## Feature 6: Time period for checking

Description: Configurable time period to verify password has not changed in IdP provider. If changed, user is prompted with web view to re-authenticate.
Success Criteria: Verify via logging or other means of status, verify that check for password sync is done on the configured time period.
