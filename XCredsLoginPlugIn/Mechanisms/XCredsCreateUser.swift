//
//  CreateUser.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/21/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import OpenDirectory


/// Mechanism to create a local user and homefolder.
class XCredsCreateUser: XCredsBaseMechanism {

    let createUserLog = "createUserLog"
    let uiLog = "uiLog"
    //MARK: - Properties
    let session = ODSession.default()
    
    
    /// Native attributes that are all set to the user's shortname on account creation to give them
    /// the ability to update the items later.
    var nativeAttrsWriters = ["dsAttrTypeNative:_writers_AvatarRepresentation",
                              "dsAttrTypeNative:_writers_hint",
                              "dsAttrTypeNative:_writers_jpegphoto",
                              "dsAttrTypeNative:_writers_picture",
                              "dsAttrTypeNative:_writers_unlockOptions",
                              "dsAttrTypeNative:_writers_UserCertificate",
                              "dsAttrTypeNative:_writers_realname"]
    
    /// Native attributes that are simply set to OS defaults on account creation.
    let nativeAttrsDetails = ["dsAttrTypeNative:AvatarRepresentation": "",
                              "dsAttrTypeNative:unlockOptions": "0"]
    
    @objc override   func run() {
        os_log("CreateUser mech starting", log: createUserLog, type: .debug)
        
        // check if we are a guest account
        // if so, remove any existing user/home for the guest
        // then allow the mech to create a new user/home
        
        if (getHint(type: .guestUser) as? String == "true") {
            os_log("Setting up a guest account", log: createUserLog, type: .default)
            
            guard let password = passwordContext else {
                os_log("No username, denying login", log: createUserLog, type: .error)
                denyLogin()
                return
            }
            
            let result = cliTask("/usr/sbin/sysadminctl", arguments: ["-deleteUser", xcredsUser ?? "NONE"], waitForTermination: true)
            
            try? result.write(toFile: "/tmp/sysadminctl.output", atomically: true, encoding: String.Encoding.utf8)
            
            if let path = getManagedPreference(key: .GuestUserAccountPasswordPath) as? String {
                do {
                    let pass = password + "\n"
                    try pass.write(toFile: path + "-\(xcredsUser!)", atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    os_log("Unable to write out guest password", log: createUserLog, type: .error)
                }
            }
        }
        
        if xcredsPass != nil && !XCredsCreateUser.checkForLocalUser(name: xcredsUser!) {
            
            var secureTokenCreds = [String:String]()
            if getManagedPreference(key: .ManageSecureTokens) as? Bool ?? false {
                secureTokenCreds = GetSecureTokenCreds()
            }
            
            guard let uid = findFirstAvaliableUID() else {
                os_log("Could not find an available UID", log: createUserLog, type: .debug)
                return
            }
            
            os_log("Checking for createLocalAdmin key", log: createUserLog, type: .debug)
            var isAdmin = false
            if let createAdmin = getManagedPreference(key: .CreateAdminUser) as? Bool {
                isAdmin = createAdmin
                os_log("Found a createLocalAdmin key value: %{public}@", log: createUserLog, type: .debug, isAdmin.description)
            }
            
            os_log("Checking for CreateAdminIfGroupMember groups", log: uiLog, type: .debug)
            if let adminGroups = getManagedPreference(key: .CreateAdminIfGroupMember) as? [String] {
                os_log("Found a CreateAdminIfGroupMember key value:  ", log: uiLog, type: .debug)
                nomadGroups?.forEach { group in
                    if adminGroups.contains(group) {
                        isAdmin = true
                        os_log("User is a member of %{public}@ group. Setting isAdmin = true ", log: uiLog, type: .debug, group)
                    }
                }
            }
            var customAttributes = [String: String]()
            
            let metaPrefix = "_xcreds"
            
            customAttributes["dsAttrTypeNative:\(metaPrefix)_didCreateUser"] = "1"
            
            let currentDate = ISO8601DateFormatter().string(from: Date())
            customAttributes["dsAttrTypeNative:\(metaPrefix)_creationDate"] = currentDate
            
//            customAttributes["dsAttrTypeNative:\(nomadMetaPrefix)_domain"] = nomadDomain!
            
            createUser(shortName: xcredsUser!,
                       first: xcredsFirst!,
                       last: xcredsLast!,
                       pass: xcredsPass!,
                       uid: uid,
                       gid: "20",
                       canChangePass: true,
                       isAdmin: isAdmin,
                       customAttributes: customAttributes,
                       secureTokenCreds: secureTokenCreds)
            
            os_log("Creating local homefolder for %{public}@", log: createUserLog, type: .debug, xcredsUser!)
            createHomeDirFor(xcredsUser!)
            os_log("Fixup home permissions for: %{public}@", log: createUserLog, type: .debug, xcredsUser!)
            let _ = cliTask("/usr/sbin/diskutil resetUserPermissions / \(uid)", arguments: nil, waitForTermination: true)
            os_log("Account creation complete, allowing login", log: createUserLog, type: .debug)
        } else {
            
            // Checking to see if we are doing a silent overwrite
            if getHint(type: .passwordOverwrite) as? Bool ?? false && !(getManagedPreference(key: .GuestUserAccounts) as? [String] ?? ["Guest", "guest"]).contains(xcredsUser!){
                os_log("Password Overwrite enabled and triggered, starting evaluation", log: createUserLog, type: .debug)
                
                // Checking to see if we can get secureToken Creds
                var secureTokenCreds = ["username":"", "password":""]
                if getManagedPreference(key: .ManageSecureTokens) as? Bool ?? false {
                    secureTokenCreds = GetSecureTokenCreds()
                }
                let secureTokenCredsHeld = (secureTokenCreds["username"] != "")
                    
                // Checking Secure Token system status
                let secureTokenUsers = GetSecureTokenUserList()
                if secureTokenUsers.contains(xcredsUser!){
                    
                    // Doing more checks
                    if secureTokenUsers.count == 1 {
                        os_log("%{public}@ is the only SecureToken enabled user, unable to update the user", log: createUserLog, type: .debug, xcredsUser!)
                    } else {
                        // System is in a state where we can do secure token operations
                        if secureTokenCredsHeld {
                            // We can do secureToken operations
                            os_log("SecureToken operations needed", log: createUserLog, type: .debug)
                            
                            do {
                                // Save off the OD record
                                os_log("Getting and saving the ODRecord", log: createUserLog, type: .debug)
                                let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
                                let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: xcredsUser!, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
                                let records = try query.resultsAllowingPartial(false) as! [ODRecord]
                                let user = records.first!
                                let userInfo = try user.recordDetails(forAttributes: nil)
                                
                                // Delete the user but keep home directory
                                os_log("Deleteing the ODRecord to wipe the secureToken", log: createUserLog, type: .debug)
                                try user.delete()
                                
                                // Re-create user with OD record and new password
                                os_log("re-creating the ODRecord", log: createUserLog, type: .debug)
                                let newUser = try node.createRecord(withRecordType: kODRecordTypeUsers, name: xcredsUser!, attributes: userInfo)
                                try newUser.changePassword(nil, toPassword: xcredsPass!)
                                
                                // Give the user a secure token
                                addSecureToken(xcredsUser!, xcredsPass!, secureTokenCreds["username"] ?? "", secureTokenCreds["password"] ?? "")
                                
                                // Rotate token creds
                                let secureTokenManagementPasswordLocation = getManagedPreference(key: .SecureTokenManagementPasswordLocation) as? String ?? "/var/db/.nomadLoginSecureTokenPassword"
                                _ = CreateSecureTokenManagementUser(String(describing: secureTokenCreds["username"]!), secureTokenManagementPasswordLocation)
                            } catch {
                                os_log("Password Overwrite Silent with SecureToken Failed", log: createUserLog, type: .debug)
                            }
                            
                        } else {
                            os_log("User has a SecureToken and we do not, unable to update the user", log: createUserLog, type: .debug)
                            // we can't do secureToken operations
                        }
                    }
                } else {
                    // User does not have a secureToken
                    os_log("%{public}@ does not have token, resetting password", log: createUserLog, type: .debug, xcredsUser!)
                    
                    // changing the with OpenDirectory
                    do {
                        let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
                        let user = try node.record(withRecordType: kODRecordTypeUsers, name: xcredsUser!, attributes: kODAttributeTypeRecordName)
                        try user.changePassword(nil, toPassword: xcredsPass!)
                        
                    } catch {
                        os_log("Password Overwrite Silent without SecureToken Failed")
                    }
                }
            } else {
                // no user to create
                os_log("Skipping local account creation", log: createUserLog, type: .default)
            }
            
            // Set the login timestamp if requested
            setTimestampFor(xcredsUser ?? "")
        }
        os_log("Allowing login", log: createUserLog, type: .debug)
        let _ = allowLogin()
        os_log("CreateUser mech complete", log: createUserLog, type: .debug)
    }
    
    // mark utility functions
    func createUser(shortName: String, first: String, last: String, pass: String?, uid: String, gid: String, canChangePass: Bool, isAdmin: Bool, customAttributes: [String:String], secureTokenCreds: [String:String]) {
        var newRecord: ODRecord?
        os_log("Creating new local account for: %{public}@", log: createUserLog, type: .default, shortName)
//        os_log("New user attributes. first: %{public}@, last: %{public}@, uid: %{public}@, gid: %{public}@, canChangePass: %{public}@, isAdmin: %{public}@, customAttributes: %{public}@", log: createUserLog, type: .debug, first, last, uid, gid, canChangePass.description, isAdmin.description, customAttributes)
        
        // note for anyone following behind me
        // you need to specify the attribute values in an array
        // regardless of if there's more than one value or not
        
        os_log("Checking for UserProfileImage key", log: createUserLog, type: .debug)


        var userPicture = getManagedPreference(key: .UserProfileImage) as? String ?? ""
        
        if userPicture.isEmpty && !FileManager.default.fileExists(atPath: userPicture) {
            os_log("Key did not contain an image, randomly picking one", log: createUserLog, type: .debug)
            userPicture = randomUserPic()
        }

        os_log("userPicture is: %{public}@", log: createUserLog, type: .debug, userPicture)
        
        // Adds kODAttributeTypeJPEGPhoto as data, seems to be necessary for the profile pic to appear everywhere expected.
        // Does not necessarily have to be in JPEG format. TIF and PNG both tested okay
        // Apple seems to populate both kODAttributeTypePicture and kODAttributeTypeJPEGPhoto from the GUI user creator
        
        // Removing to test for @nstrauss
        // let picURL = URL(fileURLWithPath: userPicture)
        // let picData = NSData(contentsOf: picURL)
        // let picString = picData?.description ?? ""

        var attrs: [AnyHashable:Any] = [
            kODAttributeTypeFullName: [first + " " + last],
            kODAttributeTypeNFSHomeDirectory: [ "/Users/" + shortName ],
            kODAttributeTypeUserShell: ["/bin/bash"],
            kODAttributeTypeUniqueID: [uid],
            kODAttributeTypePrimaryGroupID: [gid],
            kODAttributeTypeAuthenticationHint: [""],
            kODAttributeTypePicture: [userPicture],
            //kODAttributeTypeJPEGPhoto: [picString],
            kODAttributeADUser: [getHint(type: .kerberos_principal) as? String ?? ""]
        ]
        
        if #available(macOS 10.15, *) {
            os_log("Replacing default bash shell with zsh for Catalina and above", log: createUserLog, type: .debug)
            attrs[kODAttributeTypeUserShell] = ["/bin/zsh"]
        }
        
        if getManagedPreference(key: .UseCNForFullName) as? Bool ?? false {
            attrs[kODAttributeTypeFullName] = [getHint(type: .fullName) as? String ?? ""]
        } else if getManagedPreference(key: .UseCNForFullNameFallback) as? Bool ?? false && "\(first) \(last)" == " " {
            attrs[kODAttributeTypeFullName] = [getHint(type: .fullName) as? String ?? ""]
        }
        
        
        if let signInTime = getHint(type: .networkSignIn) {
            attrs[kODAttributeNetworkSignIn] = [signInTime]
        }
        
        do {
            os_log("Creating user account in local ODNode", log: createUserLog, type: .debug)
            let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
            newRecord = try node.createRecord(withRecordType: kODRecordTypeUsers, name: shortName, attributes: attrs)
        } catch {
            let errorText = error.localizedDescription
            os_log("Unable to create account. Error: %{public}@", log: createUserLog, type: .error, errorText)
            return
        }
        os_log("Local ODNode user created successfully", log: createUserLog, type: .debug)
        
        os_log("Setting native attributes", log: createUserLog, type: .debug)
        if #available(macOS 10.13, *) {
            os_log("We are on 10.13 so drop the _writers_realname", log: createUserLog, type: .debug)
            nativeAttrsWriters.removeLast()
        }
        
        for item in nativeAttrsWriters {
            do {
                os_log("Setting %{public}@ attribute for new local user", log: createUserLog, type: .debug, item)
                try newRecord?.addValue(shortName, toAttribute: item)
            } catch {
                os_log("Failed to set attribute: %{public}@", log: createUserLog, type: .error, item)
            }
        }
        
        for item in nativeAttrsDetails {
            do {
                os_log("Setting %{public}@ attribute for new local user", log: createUserLog, type: .debug, item.key)
                try newRecord?.addValue(item.value, toAttribute: item.key)
            } catch {
                os_log("Failed to set attribute: %{public}@", log: createUserLog, type: .error, item.key)
            }
        }
        
        if canChangePass {
            do {
                os_log("Setting _writers_passwd for new local user", log: createUserLog, type: .debug)
                try newRecord?.addValue(shortName, toAttribute: "dsAttrTypeNative:_writers_passwd")
            } catch {
                os_log("Unable to set _writers_passwd", log: createUserLog, type: .error)
            }
        }
        
        if let password = pass {
            do {
                os_log("Setting password for new local user", log: createUserLog, type: .debug)
                try newRecord?.changePassword(nil, toPassword: password)
            } catch {
                os_log("Error setting password for new local user", log: createUserLog, type: .error)
            }
        }
        
        if customAttributes.isEmpty == false {
            os_log("Setting additional attributes for new local user", log: createUserLog, type: .debug)
            for item in customAttributes {
                do {
                    os_log("Setting %{public}@ attribute for new local user, value: %{public}@", log: createUserLog, type: .debug, item.key, item.value)
                    try newRecord?.addValue(item.value, toAttribute: item.key)
                } catch {
                    os_log("Failed to set additional attribute: %{public}@", log: createUserLog, type: .error, item.key)
                }
            }
        }
        
        if isAdmin {
            do {
                os_log("Find the administrators group", log: createUserLog, type: .debug)
                let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
                let query = try ODQuery.init(node: node,
                                             forRecordTypes: kODRecordTypeGroups,
                                             attribute: kODAttributeTypeRecordName,
                                             matchType: ODMatchType(kODMatchEqualTo),
                                             queryValues: "admin",
                                             returnAttributes: kODAttributeTypeNativeOnly,
                                             maximumResults: 1)
                let results = try query.resultsAllowingPartial(false) as! [ODRecord]
                let adminGroup = results.first
                
                os_log("Adding user to administrators group", log: createUserLog, type: .debug)
                try adminGroup?.addMemberRecord(newRecord)
        
            } catch {
                let errorText = error.localizedDescription
                os_log("Unable to add user to administrators group: %{public}@", log: createUserLog, type: .error, errorText)
            }
        }
        
        // Doing Secure Token Operations
        os_log("Starting SecureToken Operations", log: createUserLog, type: .debug)
        if #available(OSX 10.13.4, *), getManagedPreference(key: .ManageSecureTokens) as? Bool ?? false && !(getManagedPreference(key: .GuestUserAccounts) as? [String] ?? ["Guest", "guest"]).contains(xcredsUser!){
            
            // Checking to make sure secureToken credentials are accessible.
            if secureTokenCreds["username"] != "" {
            
                if !(getManagedPreference(key: .SecureTokenManagementEnableOnlyAdminUsers) as? Bool ?? false && !isAdmin) {
                    os_log("Manage SecureTokens is Enabled, Giving the user a token", log: createUserLog, type: .debug)
                    addSecureToken(shortName, pass, secureTokenCreds["username"] ?? "", secureTokenCreds["password"] ?? "")
                
                    if getManagedPreference(key: .SecureTokenManagementOnlyEnableFirstUser) as? Bool ?? false {
                        // Now that the user is given a token we need to remove the service account
                        os_log("Enable Only First user Enabled, deleting the service account", log: createUserLog, type: .debug)
                        
                        // Nuking the account in unrecoverable fashion. If the secure token operation were to fail above the following deletion command will also fail and leave us in a recoverable state
                        let launchPath = "/usr/sbin/sysadminctl"
                        let args = [
                            "-deleteUser",
                            "\(String(describing: secureTokenCreds["username"]))",
                            "-secure"
                        ]
                        _ = cliTask(launchPath, arguments: args, waitForTermination: true)
                    } else {
                        os_log("Rotating the service account password", log: createUserLog, type: .debug)
                    
                        // Rotating the Secure Token passphrase
                        let secureTokenManagementPasswordLocation = getManagedPreference(key: .SecureTokenManagementPasswordLocation) as? String ?? "/var/db/.nomadLoginSecureTokenPassword"
                        _ = CreateSecureTokenManagementUser(String(describing: secureTokenCreds["username"]!), secureTokenManagementPasswordLocation)
                    }
                }
                
            // This else if is to maintain historic functionality that the first user logging in with EnableFDE enabled will be given a Secure Token
            } else if getManagedPreference(key: .EnableFDE) as? Bool ?? false {
                os_log("Historic EnableFDE function enabled, Assigning the user a token then deleting the service account", log: createUserLog, type: .debug)
                addSecureToken(shortName, pass, secureTokenCreds["username"] ?? "", secureTokenCreds["password"] ?? "")
                let launchPath = "/usr/sbin/sysadminctl"
                let args = [
                    "-deleteUser",
                    "\(String(describing: secureTokenCreds["username"]))",
                    "-secure"
                ]
                _ = cliTask(launchPath, arguments: args, waitForTermination: true)
            }
        } else {
            os_log("SecureToken Credentials inaccessible, failing silently", log: createUserLog, type: .error)
        }
        
        os_log("Checking for aliases to add...", log: createUserLog, type: .debug)
        
        if getManagedPreference(key: .AliasUPN) as? Bool ?? false {
            if let upn = getHint(type: .kerberos_principal) as? String {
                os_log("Adding UPN as an alias: %{public}@", log: createUserLog, type: .debug, upn)
                let result = XCredsCreateUser.addAlias(name: shortName, alias: upn.lowercased())
                os_log("Adding UPN result: %{public}@", log: createUserLog, type: .debug, result.description)
            }
        }
        
        if getManagedPreference(key: .AliasNTName) as? Bool ?? false {
            if let ntName = getHint(type: .ntName) as? String {
                os_log("Adding NTName as an alias: %{public}@", log: createUserLog, type: .debug, ntName)
                let result = XCredsCreateUser.addAlias(name: shortName, alias: ntName)
                os_log("Adding NTName result: %{public}@", log: createUserLog, type: .debug, result.description)
            }
        }
        
        os_log("User creation complete for: %{public}@", log: createUserLog, type: .debug, shortName)
    }
    
    // func to get a random string
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }

    //TODO: Change to throws instead of optional.
    /// Finds the first avaliable UID in the DSLocal domain above 500 and returns it as a `String`
    ///
    /// - Returns: `String` representing the UID
    func findFirstAvaliableUID() -> String? {
        var newUID = ""
        os_log("Checking for avaliable UID", log: createUserLog, type: .debug)
        
        if let uidToolpath = getManagedPreference(key: .UIDTool) as? String {
            os_log("Checking UIDTool", log: createUserLog, type: .debug)
            if FileManager.default.isExecutableFile(atPath: uidToolpath) {
                os_log("Calling UIDTool", log: createUserLog, type: .debug)
                let uid = cliTask(uidToolpath, arguments: [xcredsUser ?? "NONE" ], waitForTermination: true)
                if uid != "" {
                    os_log("Found custom uid, using: %{public}@", log: createUserLog, type: .debug, uid)
                    return uid.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
            }
        }
        
        for potentialUID in 501... {
            do {
                let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
                let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeUniqueID, matchType: ODMatchType(kODMatchEqualTo), queryValues: String(potentialUID), returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
                let records = try query.resultsAllowingPartial(false) as! [ODRecord]
                if records.isEmpty {
                    newUID = String(potentialUID)
                    break
                }
            } catch {
                let errorText = error.localizedDescription
                os_log("ODError searching for avaliable UID: %{public}@", log: createUserLog, type: .error, errorText)
                return nil
            }
        }
        os_log("Found first available UID: %{public}@", log: createUserLog, type: .default, newUID)
        return newUID
    }

    //TODO: Convert to throws
    /// Finds the local homefolder template that corresponds to the locale of the system and copies it into place.
    ///
    /// - Parameter user: The shortname of the user to create a home for as a `String`.
    func createHomeDirFor(_ user: String) {
        os_log("Find system locale...", log: createUserLog, type: .debug)
        let currentLanguage = Locale.current.languageCode ?? "Non_localized"
        os_log("System language is: %{public}@", log: createUserLog, type: .debug, currentLanguage)
        let templateName = templateForLang(currentLanguage)
        let sourceURL = URL(fileURLWithPath: "/System/Library/User Template/" + templateName)
        let homeDirLocations = ["Desktop", "Downloads", "Documents", "Movies", "Music", "Pictures", "Public"]
        do {
            os_log("Initializing the user home directory", log: createUserLog, type: .debug)
            try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: "/Users/" + user))
            
            os_log("Copying non-localized folders to new home", log: createUserLog, type: .debug)
            for location in homeDirLocations {
                try FileManager.default.copyItem(at: URL(fileURLWithPath: "/System/Library/User Template/Non_localized/\(location)"), to: URL(fileURLWithPath: "/Users/" + user + "/\(location)"))
            }
            
            os_log("Copying language template", log: createUserLog, type: .debug)
            try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: "/Users/" + user))
        } catch {
            os_log("Home template copy failed with: %{public}@", log: createUserLog, type: .error, error.localizedDescription)
        }
    }
    
    /// Looks at the Apple provided User Pictures directory, recurses it, and delivers a random picture path.
    ///
    /// - Returns: A `String` path to a random user picture. If there is a failure it returns an empty `String`.
    func randomUserPic() -> String {
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .localDomainMask)
        guard let library = libraryDir.first else {
            return ""
        }
        let picturePath = library.appendingPathComponent("User Pictures", isDirectory: true)
        let picDirs = (try? FileManager.default.contentsOfDirectory(at: picturePath, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles)) ?? []
        let pics = picDirs.flatMap {(try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: [URLResourceKey.isRegularFileKey], options: .skipsHiddenFiles)) ?? []}
        return pics[Int(arc4random_uniform(UInt32(pics.count)))].path
    }
    
    /// Given an connonical ISO language code, find and return the macOS home folder template name that is appropriate.
    ///
    /// - Parameter code: The `languageCode` of the current user `Locale`.
    ///             You can find the current language with `Locale.current.languageCode`
    /// - Returns: A `String` that is the name of the localized home folder template on macOS. If the language code doesn't
    ///             map to one of the default macOS home templates the `Non_localized` name will be returned.
    func templateForLang(_ code: String) -> String {
        let templateName = ".lproj"
        switch code {
        case "es":
            return "Spanish" + templateName
        case "nl":
            return "Dutch" + templateName
        case "en":
            return "English" + templateName
        case "fr":
            return "French" + templateName
        case "it":
            return "Italian" + templateName
        case "de":
            return "German" + templateName
        case "ja":
            return "Japanese" + templateName
        case "ar":
            return "ar" + templateName
        case "ca":
            return "ca" + templateName
        case "cs":
            return "cs" + templateName
        case "da":
            return "da" + templateName
        case "el":
            return "el" + templateName
        case "es-419":
            return "es_419" + templateName
        case "fi":
            return "fi" + templateName
        case "he":
            return "he" + templateName
        case "hi":
            return "hi" + templateName
        case "hr":
            return  "hr" + templateName
        case "hu":
            return "hu" + templateName
        case "id":
            return "id" + templateName
        case "ko":
            return "ko" + templateName
        case "ms":
            return "ms" + templateName
        case "nb":
            return "no" + templateName
        case "pl":
            return "pl" + templateName
        case "pt":
            return "pt" + templateName
        case "pt-PT":
            return "pt_PT" + templateName
        case "ro":
            return "ro" + templateName
        case "ru":
            return "ru" + templateName
        case "sk":
            return "sk" + templateName
        case "sv":
            return "sv" + templateName
        case "th":
            return "th" + templateName
        case "tr":
            return "tr" + templateName
        case "uk":
            return "uk" + templateName
        case "vi":
            return "vi" + templateName
        case "zh-Hans":
            return "zh_CN" + templateName
        case "zh-Hant":
            return "zh_TW" + templateName
        default:
            return "Non_localized"
        }
    }
    
    fileprivate func setTimestampFor(_ nomadUser: String) {
        // Add network sign in stamp
        if let signInTime = getHint(type: .networkSignIn) {
            if XCredsCreateUser.updateSignIn(name: nomadUser, time: signInTime as AnyObject) {
                os_log("Sign in time updated", log: createUserLog, type: .default)
            } else {
                os_log("Dould not add timestamp", log: createUserLog, type: .error)
            }
        }
    }
    
    fileprivate func addSecureToken(_ username: String, _ userPass: String?,_ adminUsername: String,_ adminPassword: String?) {
        //MARK: 10.14 fix
        // check for 10.14
        // check for no existing local users?
        // - perhaps looking for diskutil apfs listcryptousers /
        //     if a user already has a token, this will fail anyway
        // - gate behind a pref key?
        
        // attempt to add token to user
        
        
        os_log("Attempting to add a token to new user.", log: createUserLog, type: .default)
        
        let launchPath = "/usr/sbin/sysadminctl"
        
        var args = [
            "-secureTokenOn",
            username,
            "-password",
            userPass ?? "",
            "-adminUser",
            adminUsername,
            "-adminPassword",
            adminPassword ?? ""
        ]
        
        let result = cliTask(launchPath, arguments: args, waitForTermination: true)
        os_log("sysdaminctl result: %{public}@", log: createUserLog, type: .debug, result)
        args = [
            "********",
            "********",
            "********",
            "********",
            "********",
            "********",
            "********",
            "********"
        ]
    }
    
    fileprivate func isFdeEnabled() -> Bool {
        
        // check to see if FV is already running
        
        let launchPath = "/usr/bin/fdesetup"
        let args = [
            "status"
        ]
        if cliTask(launchPath, arguments: args, waitForTermination: true).contains("FileVault is Off") {
            return false
        } else {
            return true
        }
    }
    
    fileprivate func GetSecureTokenCreds() -> [String:String] {
        
        os_log("Starting SecureToken Credential acquisition process", log: createUserLog, type: .default)
        
        // Initializing the return variables
        var secureTokenCreds = ["username":"",
                                "password":""]
        
        // Getting the list of secure token enabled users
        let secureTokenUsers = GetSecureTokenUserList()
        os_log("SecureToken Authorized Users: %{public}@", log: createUserLog, type: .default, secureTokenUsers.joined(separator: ", "))
        
        // Reading the managed perferences
        let secureTokenManagementUsername = getManagedPreference(key: .SecureTokenManagementUsername) as? String ?? "_nomadlogin"
        let secureTokenManagementPasswordLocation = getManagedPreference(key: .SecureTokenManagementPasswordLocation) as? String ?? "/var/db/.nomadLoginSecureTokenPassword"
        var secureTokenUserCreated = false
        
        // Doing base analysis
        if secureTokenUsers.count == 0 {
            // Nobody has the initial token
            if !CreateSecureTokenManagementUser(secureTokenManagementUsername, secureTokenManagementPasswordLocation){
                os_log("Unable to create SecureToken User", log: createUserLog, type: .error)
            }
            let secureTokenManagementPassword = String(data: FileManager.default.contents(atPath: secureTokenManagementPasswordLocation)!, encoding: .ascii)!
            addSecureToken(secureTokenManagementUsername, secureTokenManagementPassword, secureTokenManagementUsername, secureTokenManagementPassword)
            secureTokenUserCreated = true
        }
        
        if secureTokenUsers.contains(secureTokenManagementUsername) || secureTokenUserCreated {
            // The Secure Token management account has a token
            
            // Assigning the username to the return variable
            secureTokenCreds["username"] = secureTokenManagementUsername
            
            // Getting the secureToken creds from the saved file
            os_log("Retrieving password from %{public}@", log: createUserLog, type: .debug, secureTokenManagementPasswordLocation)
            secureTokenCreds["password"] = String(data: FileManager.default.contents(atPath: secureTokenManagementPasswordLocation)!, encoding: .ascii)!
            
        } else {
            // The Secure Token management account does not have a token, but there are tokens already given
            os_log("Secure Token management unable to get credentials", log: createUserLog, type: .error)
        }
        return secureTokenCreds
    }
    
    fileprivate func CreateSecureTokenManagementUser(_ username: String,_ passwordLocation: String) -> Bool{
        
        // Generating a random password string and assigning that as the password to the user
        let password = randomString(length: getManagedPreference(key: .SecureTokenManagementPasswordLength) as? Int ?? 16)
        
        // Checking if the account exists
        if cliTask("/usr/bin/dscl", arguments: [".", "-list", "/Users"], waitForTermination: true).components(separatedBy: "\n").contains(username){
            // User already exists, should rotate the password
            os_log("Secure Token management account exists, rotating password", log: createUserLog, type: .default)
            
            // Getting the old password
            let oldPassword = String(data: FileManager.default.contents(atPath: passwordLocation)!, encoding: .ascii)!
            
            // rotating the password
            let launchPath = "/usr/sbin/sysadminctl"
            let args = [
                "-resetPasswordFor",
                "\(username)",
                "-newPassword",
                "\(password)",
                "-adminUser",
                "\(username)",
                "-adminPassword",
                "\(oldPassword)"
            ]
            _ = cliTask(launchPath, arguments: args, waitForTermination: true)
            
        } else {
            os_log("Secure Token management account being created", log: createUserLog, type: .default)
        
            // Creating the user record with sysadminctl becuase it does the magic that allows it to delegate tokens vs manually creating via dscl
            var launchPath = "/usr/sbin/sysadminctl"
            var args = [
                "-addUser",
                "\(username)",
                "-password",
                "\(password)",
                "-UID",
                getManagedPreference(key: .SecureTokenManagementUID) as? String ?? "400",
                "-fullName",
                getManagedPreference(key: .SecureTokenManagementFullName) as? String ?? "NoMAD Login",
                "-home",
                "/private/var/_nomadlogin",
                "-admin",
                "-picture",
                getManagedPreference(key: .SecureTokenManagementIconPath) as? String ?? "/Library/Security/SecurityAgentPlugins/NoMADLoginAD.bundle/Contents/Resources/NoMADFDEIcon.png"
            ]
            _ = cliTask(launchPath, arguments: args, waitForTermination: true)
            
            // Making the user hiddem
            launchPath = "/usr/bin/dscl"
            args = [
                ".",
                "-create",
                "/Users/\(username)",
                "IsHidden",
                "1"
            ]
            _ = cliTask(launchPath, arguments: args, waitForTermination: true)
            
        }
        
        // Saving that password to the password location
        do {
            try password.write(toFile: passwordLocation, atomically: true, encoding: String.Encoding.ascii)
            var attributes = [FileAttributeKey : Any]()
            attributes[.posixPermissions] = 0o600
            try FileManager.default.setAttributes(attributes, ofItemAtPath: passwordLocation)
        } catch {
            os_log("Error writing password to: %{public}@", log: createUserLog, type: .debug, passwordLocation)
            return false
        }
        return true
    }
    
    fileprivate func GetSecureTokenUserList() -> [String] {
        let launchPath = "/usr/bin/fdesetup"
        let args = [
            "list"
        ]
        let secureTokenListRaw = cliTask(launchPath, arguments: args, waitForTermination: true)
        let partialList = secureTokenListRaw.components(separatedBy: "\n")
        var secureTokenUsers = [String]()
        for entry in partialList {
            let username = entry.components(separatedBy: ",")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if username != ""{
                secureTokenUsers.append(entry.components(separatedBy: ",")[0])
            }
        }
        
        return secureTokenUsers
    }
}
