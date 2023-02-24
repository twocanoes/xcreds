# XCreds Setup with Google OIDC #

Example mobile config on the [release page](../releases/latest).
Release and Beta Builds can be found on the [release page](../releases)

To use XCreds with Google as the OIDC provider:

1. Makes sure you use build 1276 or later of XCreds.

2. Create a project or select an existing project in the google cloud console.

3. go to API & Services-> Credentials. 

4. Create a consent screen by clicking the Configure Consent Screen:

![consent screen](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/9initialconsent.jpg)

5. Select User Type as Internal (or as appropriate for your organization):

![User Type](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/8initialconsent.jpg)

6. Fill out the App information with your organization appropriate info:

![app info](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/7consent.jpg)

7. Leave Scopes empty:

![scopes](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/6scopes.jpg)

8. Go to the credential section and add an OAuth Client ID by clicking Create Credentials->OAuth Client ID

![](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/1create%20clientid.jpg)

9. Select the Web Application and the following details:

Application Type: Web Application

Name: XCreds

Redirect URL: https://127.0.0.1/xcreds

![](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/2add%20details.jpg)

10. copy client id and secret

![](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/3client%20secret.jpg)

11. Create a profile and make sure to change the scope to not include offline access (scopes should be "profile openid" and to include the special shouldSetGoogleAccessTypeToOffline key.

![](https://twocanoes-app-resources.s3.amazonaws.com/xcreds/wiki/google-oidc/4settings.jpg)