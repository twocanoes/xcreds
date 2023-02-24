# XCreds Setup with Azure OIDC #

Example mobile config on the [release page](../releases/latest).
Release and Beta Builds can be found on the [release page](../releases)

1. In azure, create an app registration, give it a name and a redirect URI of type Mobile with a value of "xcreds://auth/" and select Register. Do not forget the trailing slash in the redirect URI.


	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/app%20registration-name%20and%20redirect.png" width="1200" />

1. Once the app is created, note the Application (client) ID and the Directory (tenant) ID:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/app%20registration-app%20id%20and%20tenent.png" width="1200" />

1. Install the XCreds app and launch it. Open the preferences from the menu bar:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/prefs_menu.jpg" width="600" />

1. Enter the client and DiscoveryURL into the preferences of the app. Specify the discovery URL by adding in the tenant id from above into the Azure DiscoveryURL. For example, for tenant id e64a2b5d-3eb1-436e-9e8a-521f0c5cd489, the DiscoveryURL would be:

	https://login.microsoftonline.com/e64a2b5d-3eb1-436e-9e8a-521f0c5cd489/.well-known/openid-configuration

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/prefs.png" width="600" />
	
1. To give users access to the app, go to Azure AD->Enterprise Applications->xcreds and select Assign users and groups:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/assign%20users.png" width="1200" />

1. Select Add user/group:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/assign%20user%202.png" width="1200" />

1. Select users to add:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/assign%20user%203.png" width="1200" />
	
	
1. Select Assign to assign users to the application:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/assign.png" width="1200" />

1. Select Sign-in from menu item:


	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/sign%20in.jpg" width="600" />
	
1. A web view will appear. Enter in a valid user and authenticate:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/sign_in_view.jpg" width="600" />

1. The first time logging in, accept the application:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/requested.png" width="600" />
	
1. Look in the app preferences and verify you have tokens:

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/prefs_menu.jpg" width="600" />
	
	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/tokens.png" width="600" />

1. Verify the token is still valid (and the Azure password has not changed) by selecting Check Token from them menu item and a success message should appear.

	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/check%20token.jpg" width="600" />
	
	<img src="https://twocanoes-app-resources.s3.amazonaws.com/xcreds/checktoken.jpg" width="300" />

