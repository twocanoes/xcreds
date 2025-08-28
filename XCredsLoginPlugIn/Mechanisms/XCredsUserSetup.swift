//
//  XCredsUserSetup.swift
//
//

class XCredsUserSetup: XCredsBaseMechanism{

    @objc override func run() {
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ XCredsUserSetup mech starting ~~~~~~~~~~~~~~~~~~~")

        let bundle = Bundle.findBundleWithName(name: "XCreds")

        if let bundle = bundle {
            let infoPlist = bundle.infoDictionary
            if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"] {
                TCSLogInfoWithMark("------------------------------------------------------------------")
                TCSLogInfoWithMark("XCreds Login Build Number: \(build)")
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

            if let _ = getHint(type: .localAdmin) as? LocalAdminCredentials {
                TCSLogWithMark("local admin set in hints")
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
        updateDSRecords()


    }
    func updateDSRecords() {
        guard let nonSystemUsers = try? getAllNonSystemUsers() else{
            TCSLogWithMark("could not get non system users")
            return
        }

        for odRecord in nonSystemUsers {
            let userDetails = try? odRecord.recordDetails(forAttributes: nil)
            if let userDetails = userDetails {
                if let _ = try? odRecord.values(forAttribute: "dsAttrTypeNative:_xcreds_oidc_full_username") as? [String]{
                    TCSLogWithMark("user already has oidc full username")
                    continue
                }
                TCSLogWithMark("searching for user in user account")
                if let homeDirArray = userDetails["dsAttrTypeStandard:NFSHomeDirectory"] as? Array<String>, homeDirArray.count>0{
                    let homeDir = homeDirArray[0]
                    TCSLogWithMark("looking in \(homeDir) for ds_info.plist")
                    let appSupportFolder = homeDir + "/Library/Application Support/XCreds"
                    let plistPath = appSupportFolder + "/ds_info.plist"

                    TCSLogWithMark("looking in path \(plistPath)")
                    if FileManager.default.fileExists(atPath: plistPath){
                        TCSLogWithMark("found ds_info.plist")
                        do {
                            TCSLogWithMark("reading plist")
                            let dict = try PropertyListDecoder().decode([String:String].self, from: Data(contentsOf: URL(fileURLWithPath: plistPath)))
                            if let currOIDCFullUsername = dict["_xcreds_oidc_full_username"],
                               let oidcUsername = dict["_xcreds_oidc_username"],
                               let subValue = dict["subValue"],
                               let issuerValue = dict["issuerValue"]
                            {
                                TCSLogWithMark("updating user account info")
                                try odRecord.setValue("1", forAttribute: "dsAttrTypeNative:_xcreds_oidc_updatedfromlocal")

                                try odRecord.setValue(currOIDCFullUsername, forAttribute: "dsAttrTypeNative:_xcreds_oidc_full_username")
                                try odRecord.setValue(oidcUsername, forAttribute: "dsAttrTypeNative:_xcreds_oidc_username")
                                try odRecord.setValue(subValue, forAttribute: "dsAttrTypeNative:_xcreds_oidc_sub")
                                try odRecord.setValue(issuerValue, forAttribute: "dsAttrTypeNative:_xcreds_oidc_iss")

                                TCSLogWithMark("removing file")
                                try FileManager.default.removeItem(atPath: plistPath)

                            }
                        }
                        catch {
                            TCSLogWithMark("error decoding propertylist: \(error)")
                        }

                    }

                }
            }
        }
    }

}
