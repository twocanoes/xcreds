//
//  PrefKeys.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import OSLog
enum PrefKeys: String {
    case clientID, clientSecret, ropgResponseValue, resource, password="xcreds local password",discoveryURL, redirectURI, scopes, accessToken, idToken, refreshToken, tokenEndpoint, expirationDate, invalidToken, refreshRateHours,refreshRateMinutes, showDebug, verifyPassword, shouldShowQuitMenu, shouldShowPreferencesOnStart, shouldSetGoogleAccessTypeToOffline, passwordChangeURL, shouldShowAboutMenu, username, idpHostName, passwordElementID, shouldFindPasswordElement, shouldShowSupportStatus,shouldShowConfigureWifiButton,shouldShowMacLoginButton, loginWindowBackgroundImageURL, loginWindowSecondaryMonitorsBackgroundImageURL, shouldShowCloudLoginByDefault, shouldPreferLocalLoginInsteadOfCloudLogin, idpHostNames,autoRefreshLoginTimer, loginWindowWidth, loginWindowHeight, shouldShowRefreshBanner, shouldSwitchToLoginWindowWhenLocked,accounts = "Accounts",
         windowSignIn = "WindowSignIn", settingsOverrideScriptPath, localAdminUserName, localAdminPassword, usernamePlaceholder, passwordPlaceholder, shouldShowLocalOnlyCheckbox, shouldShowTokenUpdateStatus, shouldDetectNetworkToDetermineLoginWindow, showLoginWindowDelaySeconds, shouldPromptForMigration, shouldAllowKeyComboForMacLoginWindow, aliasName,claimsToAddToLocalUserAccount, loadPageTitle, loadPageInfo,shouldPromptForADPasswordChange, hideIfPathExists, allowedUsersArray, allowUsersClaim, mapKerberosPrincipalName, mapFirstName = "map_firstname",mapFullName = "map_fullname", mapUserName = "map_username", mapLastName = "map_lastname",menuItemWindowBackgroundImageURL, menuItems, shareMenuItemName, shouldShowSignInMenuItem, shouldLoginWindowBackgroundImageFillScreen,
    shouldLoginWindowSecondaryMonitorsBackgroundImageFillScreen,resetPasswordDialogTitle, systemInfoButtonTitle, shouldShowShutdownButton, shouldShowRestartButton, shouldShowSystemInfoButton, shouldShowMenuBarSignInWithoutLoginWindowSignin, refreshBannerText,adUserAttributesToAddToLocalUserAccount, mapUID = "map_uid", allowLoginIfMemberOfGroup, keyCodeForLoginWindowChange, mapPasswordExpiry = "map_password_expiry", menuItemIconData, menuItemIconCheckedData, mapFullUserName = "map_fullusername", ccidSlotName, shouldSuppressLocalPasswordPrompt,shouldUseKillWhenLoginWindowSwitching, upnSuffixToDomainMappings,shouldAllowLoginCardSetup,accountLockedPasswordDialogTitle,accountLockedPasswordDialogText, OIDCLastLoginTimestamp, lastOIDCLoginFailTimestamp
    case shouldUseROPGForPasswordChangeChecking
    case shouldUseROPGForMenuLogin
    case shouldUseBasicAuthWithROPG
    case shouldUseROPGForLoginWindowLogin
    case shouldActivateSystemInfoButton
    case actionItemOnly = "ActionItemOnly"
    case systemInfoAdditionsArray
    case aDDomain = "ADDomain"
    case aDSite = "ADSite"
    case additionalADDomainList = "AdditionalADDomains"
    case aDDomainController = "ADDomainController"
    case allowEAPOL = "AllowEAPOL"
    case allUserInformation = "AllUserInformation"
    case autoAddAccounts = "AutoAddAccounts"
    case autoConfigure = "AutoConfigure"
    case autoRenewCert = "AutoRenewCert"
    case changePasswordCommand = "ChangePasswordCommand"
    case changePasswordType = "ChangePasswordType"
    case changePasswordOptions = "ChangePasswordOptions"
    case caribouTime = "CaribouTime"
    case cleanCerts = "CleanCerts"
    case configureChrome = "ConfigureChrome"
    case configureChromeDomain = "ConfigureChromeDomain"
    case customLDAPAttributes = "CustomLDAPAttributes"
    case customLDAPAttributesResults = "CustomLDAPAttributesResults"
    case deadLDAPKillTickets = "DeadLDAPKillTickets"
//    case displayName = "DisplayName"
    case dontMatchKerbPrefs = "DontMatchKerbPrefs"
    case dontShowWelcome = "DontShowWelcome"
    case dontShowWelcomeDefaultOn = "DontShowWelcomeDefaultOn"
    case exportableKey = "ExportableKey"
    case firstRunDone = "FirstRunDone"
    case getCertAutomatically = "GetCertificateAutomatically"
    case getHelpType = "GetHelpType"
    case getHelpOptions = "GetHelpOptions"
    case groups = "Groups"
    case hicFix = "HicFix"
    case hideAbout = "HideAbout"
    case hideAccounts = "HideAccounts"
    case hideExpiration = "HideExpiration"
    case hideExpirationMessage = "HideExpirationMessage"
    case hideCertificateNumber = "HideCertificateNumber"
    case hideHelp = "HideHelp"
    case hideGetSoftware = "HideGetSoftware"
    case hideLastUser = "HideLastUser"
    case hideLockScreen = "HideLockScreen"
    case hideRenew = "HideRenew"
    case hidePrefs = "HidePrefs"
    case hideSignIn = "HideSignIn"
    case hideTickets = "HideTickets"
    case hideQuit = "HideQuit"
    case hideSignOut = "HideSignOut"
    case homeAppendDomain = "HomeAppendDomain"
    case iconOff = "IconOff"
    case iconOffDark = "IconOffDark"
    case iconOn = "IconOn"
    case iconOnDark = "IconOnDark"
    case kerberosRealm = "KerberosRealm"
    case keychainItems = "KeychainItems"
    case keychainItemsInternet = "KeychainItemsInternet"
    case keychainItemsCreateSerial = "KeychainItemsCreateSerial"
    case keychainItemsDebug = "KeychainItemsDebug"
    case keychainMinderWindowTitle = "KeychainMinderWindowTitle"
    case keychainMinderWindowMessage = "KeychainMinderWindowMessage"
    case keychainMinderShowReset = "KeychainMinderShowReset"
    case keychainPasswordMatch = "KeychainPasswordMatch"
    case lastCertificateExpiration = "LastCertificateExpiration"
    case lightsOutIKnowWhatImDoing = "LightsOutIKnowWhatImDoing"
    case loginComamnd = "LoginComamnd"
    case loginItem = "LoginItem"
    case ldapAnonymous = "LDAPAnonymous"
    case lDAPSchema = "LDAPSchema"
    case lDAPServerList = "LDAPServerList"
    case lDAPServerListDeny = "LDAPServerListDeny"
    case lDAPoverSSL = "LDAPOverSSL"
    case lDAPOnly = "LDAPOnly"
    case lDAPType = "LDAPType"
    case localPasswordSync = "LocalPasswordSync"
    case localPasswordSyncDontSyncLocalUsers = "LocalPasswordSyncDontSyncLocalUsers"
    case localPasswordSyncDontSyncNetworkUsers = "LocalPasswordSyncDontSyncNetworkUsers"
    case localPasswordSyncOnMatchOnly = "LocalPasswordSyncOnMatchOnly"
    case lockedKeychainCheck = "LockedKeychainCheck"
    case lastUser = "LastUser"
    case lastPasswordWarning = "LastPasswordWarning"
    case lastPasswordExpireDate = "LastPasswordExpireDate"
    case loginLogo = "LoginLogo"
    case menuAbout = "MenuAbout"
    case menuAccounts = "MenuAccounts"
    case menuActions = "MenuActions"
    case menuChangePassword = "MenuChangePassword"
    case menuHomeDirectory = "MenuHomeDirectory"
    case menuGetCertificate = "MenuGetCertificate"
    case menuGetHelp = "MenuGetHelp"
    case menuGetSoftware = "MenuGetSoftware"
    case menuFileServers = "MenuFileServers"
    case menuPasswordExpires = "MenuPasswordExpires"
    case menuPreferences = "MenuPreferences"
    case menuRenewTickets = "MenuRenewTickets"
    case menuSignIn = "MenuSignIn"
    case menuSignOut = "MenuSignOut"
    case menuTickets = "MenuTickets"
    case menuUserName = "MenuUserName"
    case menuWelcome = "MenuWelcome"
    case menuQuit = "MenuQuit"
    case menuIconColor = "MenuIconColor"
    case menuIconColorDark = "MenuIconColorDark"
    case messageLocalSync = "MessageLocalSync"
    case messageNotConnected = "MessageNotConnected"
    case messageUPCAlert = "MessageUPCAlert"
    case messagePasswordChangePolicy = "MessagePasswordChangePolicy"
    case mountSharesWithFinder = "MountSharesWithFinder"
    case passwordExpirationDays = "PasswordExpirationDays"
    case passwordExpireAlertTime = "PasswordExpireAlertTime"
    case passwordExpireCustomAlert = "PasswordExpireCustomAlert"
    case passwordExpireCustomWarnTime = "PasswordExpireCustomWarnTime"
    case passwordExpireCustomAlertTime = "PasswordExpireCustomAlertTime"
    case passwordPolicy = "PasswordPolicy"
    case persistExpiration = "PersistExpiration"
    case profileDone = "ProfileDone"
    case profileWait = "ProfileWait"
    case recursiveGroupLookup = "RecursiveGroupLookup"
    case renewTickets = "RenewTickets"
    case showHome = "ShowHome"
    case secondsToRenew = "SecondsToRenew"
    case selfServicePath = "SelfServicePath"
    case shareReset = "ShareReset"        // clean listing of shares between runs
    case signInCommand = "SignInCommand"
    case signInWindowAlert = "SignInWindowAlert"
    case signInWindowAlertTime = "SignInWindowAlertTime"
    case signInWindowOnLaunch = "SignInWindowOnLaunch"
    case signInWindowOnLaunchExclusions = "SignInWindowOnLaunchExclusions"
    case signedIn = "SignedIn"
    case signOutCommand = "SignOutCommand"
    case singleUserMode = "SingleUserMode"
    case siteIgnore = "SiteIgnore"
    case siteForce = "SiteForce"
    case slowMount = "SlowMount"
    case slowMountDelay = "SlowMountDelay"
    case stateChangeAction = "StateChangeAction"
    case switchKerberosUser = "SwitchKerberosUser"
    case template = "Template"
    case titleSignIn = "TitleSignIn"
    case uPCAlert = "UPCAlert"
    case uPCAlertAction = "UPCAlertAction"
    case userCN = "UserCN"
    case userGroups = "UserGroups"
    case userPrincipal = "UserPrincipal"
    case userHome = "UserHome"
    case userPasswordExpireDate = "UserPasswordExpireDate"
    case userCommandTask1 = "UserCommandTask1"
    case userCommandName1 = "UserCommandName1"
    case userCommandHotKey1 = "UserCommandHotKey1"
    case userPasswordSetDate = "UserPasswordSetDate"
    case useKeychain = "UseKeychain"
    case useKeychainPrompt = "UseKeychainPrompt"
    case userAging = "UserAging"
    case userAttributes = "UserAttributes"
    case userEmail = "UserEmail"
    case userFirstName = "UserFirstName"
    case userFullName = "UserFullName"
    case userLastName = "UserLastName"
    case userLastChecked = "UserLastChecked"
    case userShortName = "UserShortName"
    case userSwitch = "UserSwitch"
    case userUPN = "UserUPN"
    case verbose = "Verbose"
    case wifiNetworks = "WifiNetworks"
    case x509CA = "X509CA"
    case x509Name = "X509Name"

}
func getManagedPreference(key: Preferences) -> Any? {


    if let preference = DefaultsOverride.standardOverride.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }


    return nil
}


enum Preferences: String {

    /// The desired AD domain as a `String`.
    case ADDomain
    /// Allows appending of other domains at the loginwindow. Set as a `Bool` to allow any, or as an Array of Strings to whitelist
    case AdditionalADDomains
    /// list of domains to show in the domain pull down
    case AdditionalADDomainList
    /// add user's NT domain name as an alias to newly created accounts
    case AliasNTName
    /// add user's UPN as an alias to newly created accounts
    case AliasUPN
    /// Allow network select button on login window
    case AllowNetworkSelection
    /// Allow network text
    case AllowNetworkText
    /// A filesystem path to a background image as a `String`.
    case BackgroundImage
    /// An image to display as the background image as a Base64 encoded `String`.
    case BackgroundImageData
    /// The alpha value of the background image as an `Int`.
    case BackgroundImageAlpha
    /// Should new users be created as local administrators? Set as a `Bool`.
    case CreateAdminUser
    /// List of groups that should have its members created as local administrators. Set as an Array of Strings of the group name.
    case CreateAdminIfGroupMember
    /// Should existing mobile accounts be converted into plain local accounts? Set as a `Bool`.
    case CustomNoMADLocation
    /// If defined it specifies the custom location of the application to be given access to the keychain item. Set as a `String`
    ///
    case CustomLDAPAttributes
    case DemobilizeUsers
    /// Should we always have a password already set up before demobilizing
    case DemobilizeForcePasswordCheck
    /// Should we preserve the AltSecurityIdentities OD attribute during demobilization
    case DemobilizeSaveAltSecurityIdentities
    /// Dissallow local auth, and always do network authentication
    case DenyLocal
    /// Users to allow locally when DenyLocal is on
    case DenyLocalExcluded
    /// List of groups that should have it's members allowed to sign in. Set as an Array of Strings of the group name
    case DenyLoginUnlessGroupMember
    /// Defines which system inforation should be showed by default. Set as `String`.
    case DefaultSystemInformation
    /// Should FDE be enabled at first login on APFS disks? Set as a `Bool`.
    case EnableFDE
    /// Should the PRK be saved to disk for the MDM Escrow Service to collect? Set as a `Bool`.
    case EnableFDERecoveryKey
    // Specify a custom path for the recovery key
    case EnableFDERecoveryKeyPath
    // Should we rotate the PRK
    case EnableFDERekey
    /// Path for where the EULA acceptance info goes
    case EULAPath
    /// Text for EULA as a `String`.
    case EULAText
    /// Headline for EULA as a `String`.
    case EULATitle
    /// Subhead for EULA as a `String`.
    case EULASubTitle
    /// Allow for guest accounts
    case GuestUser
    /// the accounts to allow as an array of strings
    case GuestUserAccounts
    /// where to put the guest user password
    case GuestUserAccountPasswordPath
    /// First name for the guest user
    case GuestUserFirst
    /// Last name for  the guest user
    case GuestUserLast
    /// Ignore sites in AD. This is a compatibility measure for AD installs that have issues with sites. Set as a `Bool`.
    case IgnoreSites
    /// Adds a NoMAD entry into the keychain. `Bool` value.
    case KeychainAddNoMAD
    /// Should NoLo create a Keychain if it doesn't exist. `Bool` value.
    case KeychainCreate
    /// Should NoLo reset the Keychain if the login pass doesn't match. `Bool` value.
    case KeychainReset
    /// Force LDAP lookups to use SSL connections. Requires certificate trust be established. Set as a `Bool`.
    case LDAPOverSSL
    /// Force specific LDAP servers instead of finding them via DNS
    case LDAPServers
    /// Fallback to local auth if the network is not available
    case LocalFallback
    /// A filesystem path to an image to display on the login screen as a `String`.
    case LoginLogo
    /// Alpha value for the login logo
    case LoginLogoAlpha
    /// A Base64 encoded string of an image to display on the login screen.
    case LoginLogoData
    /// Should NoLo display a macOS-style login screen instead of a window? Set as a `Bool`,
    case LoginScreen
    /// If the create User mech should manage the SecureTokens with a service account
    case ManageSecureTokens
    /// If Notify should add additional logging
    case NotifyLogStyle
    /// NT Domain to AD domain mappings
    case NTtoADDomainMappings
    /// should we migrate users?
    case Migrate
    /// should we hide users when we migrate?
    case MigrateUsersHide
    /// If the powercontrol options should be disabled in the SignIn UI
    case PowerControlDisabled
    /// should we recursively looku groups at login
    case RecursiveGroupLookup
    /// Path to script to run, currently only one script path can be used, if you want to run this multiple times, keep the logic in your script
    case ScriptPath
    /// Arguments for the script, if any
    case ScriptArgs
    /// Should NoMAD Login enable all users that login with with a secure token as a `Bool`
    case SecureTokenManagementEnableOnlyAdminUsers
    /// Path of the icon to be used for the Secure Token management user as `String`
    case SecureTokenManagementIconPath
    /// Should NoMAD Login only enable the first admin user that login with with a secure token as a `Bool`
    case SecureTokenManagementOnlyEnableFirstUser
    /// Full Name of the Secure Token Management user as a `String`
    case SecureTokenManagementFullName
    /// The UID to use for the Management Account as a `Int` or `String`
    case SecureTokenManagementUID
    /// The location to save and read the Secure Token management password as a `String`
    case SecureTokenManagementPasswordLocation
    /// Length fo the SecureToken Management User's password as an `Int`
    case SecureTokenManagementPasswordLength
    /// Username to use to for the securetoken management account as a `String`
    case SecureTokenManagementUsername
    /// Tool to use for UID numbers
    case UIDTool
    /// Use the CN from AD as the full name
    case UseCNForFullName
    /// A string to show as the placeholder in the Username textfield
    case UseCNForFullNameFallback
    /// Uses the CN as the fullname on the account when the givenName and sn fields are blank
    case UserProfileImage

    case NormalWindowLevel
    //UserInput bits

    case UserInputOutputPath
    case UserInputUI
    case UserInputLogo
    case UserInputTitle
    case UserInputMainText

    //Messages

    case MessagePasswordSync // what to show when the password needs to sync

    //Password update keys

    case PasswordOverwriteSilent // will silently update user password to new one
    case PasswordOverwriteOptional // allow the user to stomp on the password if interested

}

