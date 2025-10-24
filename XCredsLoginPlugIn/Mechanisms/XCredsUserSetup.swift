//
//  XCredsUserSetup.swift
//
//

import ProductLicense
@available(macOS, deprecated: 11)
class XCredsUserSetup: XCredsBaseMechanism{

    @objc override func run() {
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ XCredsUserSetup mech starting ~~~~~~~~~~~~~~~~~~~")
        
        let bundle = Bundle.findBundleWithName(name: "XCreds")

        if let bundle = bundle {
            let infoPlist = bundle.infoDictionary
            if let infoPlist = infoPlist,
                let build = infoPlist["CFBundleVersion"] as? String,
                let version = infoPlist["CFBundleShortVersionString"] as? String {
                
                VersionCheck.shared.reportLicenseUsage(identifier: "com.twocanoes.xcreds", appVersion:version,buildNumber: build, event: .checkin) { isSuccess in
                    print(isSuccess)
                }

                
                TCSLogInfoWithMark("------------------------------------------------------------------")
                TCSLogInfoWithMark("XCreds Login \(version).\(build)")
                if DefaultsOverride.standardOverride.bool(forKey: "showDebug")==false {
                    TCSLogInfoWithMark("Log showing only basic info and errors.")
                    TCSLogInfoWithMark("Set debugLogging to true to show verbose logging with")
                    TCSLogInfoWithMark("sudo defaults write /Library/Preferences/com.twocanoes.xcreds showDebug -bool true")
                }
                else {
                    TCSLogInfoWithMark("To disable verbose logging:")
                    TCSLogInfoWithMark("sudo defaults delete /Library/Preferences/com.twocanoes.xcreds showDebug")

                }
                TCSLogInfoWithMark("To see all logging options, go to https://twocanoes.com/knowledge-base/capturing-xcreds-logs/")


                TCSLogInfoWithMark("------------------------------------------------------------------")
            }
        }
        TCSLogWithMark("checking to see if launchagent should be removed...")
        let fm = FileManager.default
        let launchAgentPath = "/Library/LaunchAgents/com.twocanoes.xcreds-launchagent.plist"
        let launchAgentExists = fm.fileExists(atPath: launchAgentPath)
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldRemoveMenuItemAutoLaunch.rawValue)==true, launchAgentExists == true {
            do {
                TCSLogWithMark("removing launch agent...")
                try fm.removeItem(atPath: launchAgentPath)
            }
            catch {
                TCSLogWithMark("error removing launch agent: \(error)")
            }
        }

        do {
            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)

            let users = try userManager.uidUsers()
            if let keys = users.userDict?.keys, keys.count>0{
                TCSLogWithMark("setting up tap users");
                self.setHint(type: .rfidUsers, hint: users as NSSecureCoding)
            }
            TCSLogWithMark("checking to see if we should set admin credentials")
            if let adminUser = try userManager.adminCredentials(){

                TCSLogWithMark("Setting Admin User from secure file for keychain reset")
                self.setHint(type: .localAdmin, hint: adminUser )
            }

            else if let aUsername = DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue), let aPassword =
                DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue), aUsername.isEmpty==false, aPassword.isEmpty==false{

                TCSLogWithMark("Setting Admin User from prefs / override script for keychain reset")

                let localAdmin = LocalAdminCredentials(username: aUsername, password: aPassword)
                self.setHint(type: .localAdmin, hint: localAdmin)
            }

            if let credentials = getHint(type: .localAdmin) as? LocalAdminCredentials {
                TCSLogWithMark("local admin set in hints")

                TCSLogWithMark("checking to see if we should skip filevault login by seeing if shouldSkipFileVaultLoginAdmin pref is true")
                if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldSkipFileVaultLoginAdmin.rawValue)==true,
                   filevaultAuth(username: credentials.username, password: credentials.password) == true
                {
                    TCSLogWithMark("Successfully authenticated with FileVault using local admin.")
                }
                else {
                    TCSLogWithMark( "Failed to authenticate with FileVault.")
                }
                

            }
            else {
                TCSLogWithMark("local admin not set in hints")

            }
            if let aUsername = DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue){
                TCSLogWithMark("username set: \(aUsername)")
            }
            else {
                TCSLogWithMark("username not set")
            }
            if let _ = DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue){
                TCSLogWithMark("password set")

            }
            else {
                TCSLogWithMark("password not set")

            }

        }
        catch {
            TCSLogWithMark(error.localizedDescription)
        }


        let _ = allowLogin()
//        updateDSRecords()


    }
    

}
