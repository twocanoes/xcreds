//
//  CreateUser.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/21/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import OpenDirectory


/// Mechanism to create a local user and homefolder.
class XCredsCreateUser: XCredsBaseMechanism, DSQueryable {

    let createUserLog = "createUserLog"
    let uiLog = "uiLog"
    //MARK: - Properties
    let session = ODSession.default()
    
    enum CreateUserError:Error {
        case userCreateError(String)
        case userPasswordSetError(String)
    }
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
    
    @objc override func run() {
        var localLogin=false
        TCSLogWithMark("CreateUser mech starting")

        if let localLoginHintValue = getHint(type: .localLogin) as? Bool, localLoginHintValue==true{
            TCSLogWithMark("Local Login Detected")

            localLogin=true
        }

        if let xcredsGroups = groups {

            TCSLogWithMark("group: \(xcredsGroups)")
        }

        // check if we are a guest account
        // if so, remove any existing user/home for the guest
        // then allow the mech to create a new user/home

        if (getHint(type: .guestUser) as? String == "true") {
            TCSLog("Setting up a guest account")
            
            guard let password = passwordContext else {
                TCSLogErrorWithMark("No password, denying login")
                denyLogin(message:"No password passed.")
                return
            }
            
            let result = cliTask("/usr/sbin/sysadminctl", arguments: ["-deleteUser", xcredsUser ?? "NONE"], waitForTermination: true)
            
            try? result.write(toFile: "/tmp/sysadminctl.output", atomically: true, encoding: String.Encoding.utf8)
            
            if let path = getManagedPreference(key: .GuestUserAccountPasswordPath) as? String {
                do {
                    let pass = password + "\n"
                    try pass.write(toFile: path + "-\(xcredsUser!)", atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    TCSLog("Unable to write out guest password")
                }
            }
        }
        TCSLogWithMark("user:\(xcredsUser ?? "")")
        var isAdmin = false
        var shouldRemoveAdmin = false
        if let createAdmin = getManagedPreference(key: .CreateAdminUser) as? Bool {
            isAdmin = createAdmin
            TCSLog("Found a createLocalAdmin key value: \(isAdmin.description)")
        }
        os_log("Checking for CreateAdminIfGroupMember groups", log: uiLog, type: .debug)
        if let adminGroups = getManagedPreference(key: .CreateAdminIfGroupMember) as? [String] {

            TCSLogWithMark("Found a CreateAdminIfGroupMember key value: \(String(describing: groups))")
            
            groups?.forEach { group in
                if adminGroups.contains(group) {
                    isAdmin = true
                    TCSLogWithMark("User is a member of \(group) group. Setting isAdmin = true ")
                }
            }
            if isAdmin == false, localLogin==false {
                TCSLogWithMark("admin groups defined but user is not a member, so marking remove if it exists and we created it")
                shouldRemoveAdmin = true
            }

        }
        if let xcredsPass=xcredsPass,let xcredsUser = xcredsUser, XCredsCreateUser.checkForLocalUser(name: xcredsUser)==false{
            
            var secureTokenCreds:SecureTokenCredential? = nil
            if let creds = PasswordUtils.GetSecureTokenCreds() {
                secureTokenCreds = creds
            }

            guard let uid = findFirstAvaliableUID() else {
                TCSLogErrorWithMark("Could not find an available UID")
                return
            }
            
            TCSLog("Checking for createLocalAdmin key")
            var fullname:String?

            if let fullnameHint = getHint(type: .fullName) as? String {
                fullname=fullnameHint
            }


            var customAttributes = [String: String]()
            
            let metaPrefix = "_xcreds"
            
            customAttributes["dsAttrTypeNative:\(metaPrefix)_didCreateUser"] = "1"
            
            let currentDate = ISO8601DateFormatter().string(from: Date())
            customAttributes["dsAttrTypeNative:\(metaPrefix)_creationDate"] = currentDate


            guard let xcredsFirst=xcredsFirst, let xcredsLast = xcredsLast else {
                TCSLogErrorWithMark("first or last name not defined. bailing")
                denyLogin(message:"first or last name not defined.")

                return

            }
            do {
                try createUser(shortName: xcredsUser,
                               first: xcredsFirst ,
                               last: xcredsLast, fullName: fullname,
                               pass: xcredsPass,
                               uid: uid,
                               gid: "20",
                               canChangePass: true,
                               isAdmin: isAdmin,
                               customAttributes: customAttributes,
                               secureTokenCreds: secureTokenCreds)
            }

            catch CreateUserError.userPasswordSetError(let mesg){
                denyLogin(message:mesg)
                //create home anyways because account has issues if not created even if a password is not set.
                createHome(xcredsUser:xcredsUser, uid:uid)
                return

            }
            catch{
                denyLogin(message:error.localizedDescription)
            }
            createHome(xcredsUser:xcredsUser, uid:uid)

            
        } else {

            // Checking to see if we are doing a silent overwrite
            if getHint(type: .passwordOverwrite) as? Bool ?? false && !(getManagedPreference(key: .GuestUserAccounts) as? [String] ?? ["Guest", "guest"]).contains(xcredsUser!){
                TCSLogWithMark("Password Overwrite enabled and triggered, starting evaluation")
                
                TCSLogWithMark("trying to getting admin user and password")

                if let adminUsername = getHint(type: .adminUsername) as? String,
                   let adminPassword = getHint(type: .adminPassword) as? String{
                    TCSLogWithMark("resetting password with admin username and password that was prompted before")

                    resetUserPassword(adminUserName: adminUsername, adminPassword: adminPassword)

                }
                else if let creds =  PasswordUtils.GetSecureTokenCreds(){
                    TCSLogWithMark("resetting password with admin username and password from override script")

                    resetUserPassword(adminUserName: creds.username, adminPassword: creds.password)
                }
                else {

                    TCSLogWithMark("password overwrite set but could not get admin username and password. this should not happen")
                    denyLogin(message:"password overwrite set but could not get admin username and password. this should not happen")
                    return

                }
            }
            else {
                // no user to create
                os_log("Skipping local account creation", log: createUserLog, type: .default)
            }

        }
        var alias:String?

        if let aliasHint = getHint(type: .aliasName) as? String {
            alias=aliasHint
        }
        // Set the xcreds attributes to stamp this account as the mapped one
        setTimestampFor(xcredsUser ?? "")
        let _ = updateOIDCInfo(user: xcredsUser ?? "")

        TCSLogWithMark("seeing if we have an alias")
        if let alias = alias, let xcredsUser = xcredsUser {
            TCSLogWithMark("adding alias: \(alias)")
            if XCredsCreateUser.addAlias(name: xcredsUser, alias: alias)==false {
                os_log("error adding alias", log: createUserLog, type: .debug)
            }
        }
        TCSLogWithMark("Checking if user should be made admin")
        if let xcredsUser = xcredsUser {
            do {
                let record = try getLocalRecord(xcredsUser)

                if isAdmin == true {

                    TCSLogWithMark("Making admin user")
                    if makeAdmin(record)==false {
                        os_log("failed to make user an admin", log: createUserLog, type: .error)

                    }
                }
                else if shouldRemoveAdmin == true {
                    TCSLogWithMark("removing admin if xcreds created")

                    if let promotedToAdminArray = try record.values(forAttribute: "dsAttrTypeNative:_xcreds_promoted_to_admin") as? [String],promotedToAdminArray.count==1, promotedToAdminArray[0]=="1"  {
                        TCSLogWithMark("we promoted so removing admin")

                        if removeAdmin(record)==false {
                            TCSLogErrorWithMark("failed to remove user an admin")

                        }
                        else { // success so remove attribute
                            TCSLogWithMark("removing _xcreds_promoted_to_admin from record")

                            try record.removeValues(forAttribute: "dsAttrTypeNative:_xcreds_promoted_to_admin")
                        }

                    }
                }
            }

            catch {
                os_log("error finding user to make admin", log: createUserLog, type: .error)
            }


        }




        os_log("Allowing login", log: createUserLog, type: .debug)
        let _ = allowLogin()
        os_log("CreateUser mech complete", log: createUserLog, type: .debug)
    }
    func resetUserPassword(adminUserName:String, adminPassword:String) {
        do {
            TCSLogWithMark("secure token admin user and password obtained")

            let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
            let user = try node.record(withRecordType: kODRecordTypeUsers, name: xcredsUser!, attributes: kODAttributeTypeRecordName)

            try user.setNodeCredentials(adminUserName, password: adminPassword)

            TCSLogWithMark("changing password with secure token admin")
            try user.changePassword(nil, toPassword: xcredsPass!)

        }
        catch {
            TCSLogErrorWithMark("error: \(error.localizedDescription)")
        }
    }

    func updateOIDCInfo(user: String) -> Bool {
        TCSLogWithMark("Checking for local username")
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: user, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return false
        }

        let isLocal = records.isEmpty ? false : true
        os_log("Results of local user check %{public}@", log: noLoMechlog, type: .default, isLocal.description)

        if !isLocal {
            return false
        }

        // now to update the attribute
        TCSLogWithMark("updating info in DS")
        let claimsToDSArray = (DefaultsOverride.standardOverride.array(forKey: PrefKeys.claimsToAddToLocalUserAccount.rawValue) ?? []) as? [String]

        TCSLogWithMark("Checking if member of group")
        let userGroups = getHint(type: .groups) as? [String]

        if let userGroups = userGroups, userGroups.count>0 {
            TCSLogWithMark("is a member of \(userGroups.count) groups. Adding to OD record.")
            let groupsString = userGroups.joined(separator: ",")
            try? records.first?.setValue(groupsString, forAttribute: "dsAttrTypeNative:_xcreds_groups")

        }

        TCSLogWithMark("checking for kerberos principal")
        let kerberosPrincipal = getHint(type: .kerberos_principal) as? String

        if let kerberosPrincipal = kerberosPrincipal {
            TCSLogWithMark("saving kerberos pricipal to user DS record")
            try? records.first?.setValue(kerberosPrincipal, forAttribute: "dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal")

        }

        TCSLogWithMark("setting oidc full username to DS")
        let fullUserName = getHint(type: .fullusername) as? String

        if let fullUserName = fullUserName {
            TCSLogWithMark("setting fullUserName")
            try? records.first?.setValue(fullUserName, forAttribute: "dsAttrTypeNative:_xcreds_oidc_full_username")
        }
        TCSLogWithMark("checking for alias to add as a username for rogp")
        let alias = getHint(type: .aliasName) as? String

        if let alias = alias {
            TCSLogWithMark("saving alias to DS as a username for ropg as needed")
            try? records.first?.setValue(alias, forAttribute: "dsAttrTypeNative:_xcreds_oidc_username")
        } else {
            TCSLogWithMark("Fallback,saving account name to DS as username for ropg as needed")
            try? records.first?.setValue(user, forAttribute: "dsAttrTypeNative:_xcreds_oidc_username")
        }


        let tokenArray = getHint(type: .tokens) as? Array<String>

        if let tokenArray = tokenArray , tokenArray.count>0{
            TCSLogWithMark("Found claims")
            let idToken = tokenArray[0]
            let idTokenInfo = jwtDecode(value: idToken)  //dictionary for mapping
            if let idTokenInfo = idTokenInfo {
                TCSLogWithMark("Decoded Claims")
                if var claimsToDSArray = claimsToDSArray {

                    claimsToDSArray.append("iss")
                    claimsToDSArray.append("sub")

                    for currClaim in claimsToDSArray {
                        TCSLogWithMark("Found Matching Claim: \(currClaim)")
                        if let value = idTokenInfo[currClaim] as? String {
                            let sanitizedKey = currClaim.oidc_allowed_chars
                            if sanitizedKey.count<20 || value.count<256 {
                                TCSLogWithMark("Adding \(sanitizedKey) = \(value)")
                                try? records.first?.setValue(value, forAttribute: "dsAttrTypeNative:_xcreds_oidc_\(sanitizedKey)")

                            }
                            else {
                                TCSLogWithMark("key or value too long to put into DS")
                            }

                        }
                        else if let value = idTokenInfo[currClaim] as? Array<String> {
                            let sanitizedKey = currClaim.oidc_allowed_chars
                            let oneLine = value.joined(separator: ";")
                            if sanitizedKey.count<256 || oneLine.count<20 {
                                TCSLogWithMark("Adding \(sanitizedKey) = \(oneLine)")

                                try? records.first?.setValue(oneLine, forAttribute: "dsAttrTypeNative:_xcreds_oidc_\(sanitizedKey)")
                            }
                            else {
                                TCSLogWithMark("key or value too long to put into DS")
                            }
                        }
                    }
                }
            }
        }

//        var sub:String?
//        var iss:String?
//        if let oidcSubHint = getHint(type: .oidcSub) as? String {
//            sub=oidcSubHint
//        }
//        if let oidcIssHint = getHint(type: .oidcIssuer) as? String {
//            iss=oidcIssHint
//        }
//
//        if let oidcSubHint = getHint(type: .oidcSub) as? String {
//            customAttributes["dsAttrTypeNative:\(metaPrefix)_oidc_sub"] = oidcSubHint
//        }
//        if let oidcIssHint = getHint(type: .oidcIssuer) as? String {
//            customAttributes["dsAttrTypeNative:\(metaPrefix)_oidc_iss"] = oidcIssHint
//        }

//        do {
//            os_log("updating sub",log: noLoMechlog, type: .error)
//
//            try records.first?.setValue(sub, forAttribute: "dsAttrTypeNative:_xcreds_oidc_sub")
//
//
//            os_log("updating iss",log: noLoMechlog, type: .error)
//
//            try records.first?.setValue(iss, forAttribute: "dsAttrTypeNative:_xcreds_oidc_iss")
//
//
////            if let groups = groups?.joined(separator: ";") {
////                try records.first?.setValue(groups, forAttribute: "dsAttrTypeNative:_xcreds_oidc_groups")
////
////            }
//        } catch {
//            os_log("Unable to add OIDC Info", log: noLoMechlog, type: .error)
//            return false
//        }

        return true

    }
    func createHome(xcredsUser:String, uid:String) {
        TCSLogWithMark("Creating local homefolder for \(xcredsUser)")
        createHomeDirFor(xcredsUser)
        TCSLogWithMark("Fixup home permissions for: \(xcredsUser)")
        let _ = cliTask("/usr/sbin/diskutil resetUserPermissions / \(uid)", arguments: nil, waitForTermination: true)
        TCSLogWithMark("Account creation complete, allowing login")

    }
    // mark utility functions
    func createUser(shortName: String, first: String, last: String, fullName:String?, pass: String?, uid: String, gid: String, canChangePass: Bool, isAdmin: Bool, customAttributes: [String:String], secureTokenCreds: SecureTokenCredential?) throws {
        var newRecord: ODRecord?
        os_log("Creating new local account for: %{public}@", log: createUserLog, type: .default, shortName)

        // note for anyone following behind me
        // you need to specify the attribute values in an array
        // regardless of if there's more than one value or not
        
        os_log("Checking for UserProfileImage key", log: createUserLog, type: .debug)
        var userFullName = [first, last].joined(separator: " ").trimmingCharacters(in: .whitespaces)

        if let fullName = fullName {
            userFullName=fullName
        }

        if userFullName.isEmpty {
            userFullName = shortName
        }

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
            kODAttributeTypeFullName: [userFullName],
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

        os_log("New user attributes. first: %{public}@, last: %{public}@, uid: %{public}@, gid: %{public}@, canChangePass: %{public}@, isAdmin: %{public}@, customAttributes: %{public}@", log: createUserLog, type: .debug, first, last, uid, gid, canChangePass.description, isAdmin.description, attrs.debugDescription)

        do {
            os_log("Creating user account in local ODNode", log: createUserLog, type: .debug)
            let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
            newRecord = try node.createRecord(withRecordType: kODRecordTypeUsers, name: shortName, attributes: attrs)
        } catch {
            let errorText = error.localizedDescription
            os_log("Unable to create account. Error: %{public}@", log: createUserLog, type: .error, errorText)
            throw CreateUserError.userCreateError(error.localizedDescription)
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
                //            self.updateRunDict(dict: T##Dictionary<String, Any>)

                throw CreateUserError.userPasswordSetError(error.localizedDescription)

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
        
        if isAdmin, let newRecord = newRecord {
            if makeAdmin(newRecord)==false {
                os_log("failed to make user an admin", log: createUserLog, type: .error)

            }
        }
        
        //        // Doing Secure Token Operations
        //        os_log("Starting SecureToken Operations", log: createUserLog, type: .debug)
        //        if #available(OSX 10.13.4, *), getManagedPreference(key: .ManageSecureTokens) as? Bool ?? false && !(getManagedPreference(key: .GuestUserAccounts) as? [String] ?? ["Guest", "guest"]).contains(xcredsUser!){
        //
        //            // Checking to make sure secureToken credentials are accessible.
        //            if secureTokenCreds["username"] != "" {
        //
        //                if !(getManagedPreference(key: .SecureTokenManagementEnableOnlyAdminUsers) as? Bool ?? false && !isAdmin) {
        //                    os_log("Manage SecureTokens is Enabled, Giving the user a token", log: createUserLog, type: .debug)
        //                    addSecureToken(shortName, pass, secureTokenCreds["username"] ?? "", secureTokenCreds["password"] ?? "")
        //
        //                    if getManagedPreference(key: .SecureTokenManagementOnlyEnableFirstUser) as? Bool ?? false {
        //                        // Now that the user is given a token we need to remove the service account
        //                        os_log("Enable Only First user Enabled, deleting the service account", log: createUserLog, type: .debug)
        //
        //                        // Nuking the account in unrecoverable fashion. If the secure token operation were to fail above the following deletion command will also fail and leave us in a recoverable state
        //                        let launchPath = "/usr/sbin/sysadminctl"
        //                        let args = [
        //                            "-deleteUser",
        //                            "\(String(describing: secureTokenCreds["username"]))",
        //                            "-secure"
        //                        ]
        //                        _ = cliTask(launchPath, arguments: args, waitForTermination: true)
        //                    } else {
        //                        os_log("Rotating the service account password", log: createUserLog, type: .debug)
        //
        //                        // Rotating the Secure Token passphrase
        //                        let secureTokenManagementPasswordLocation = getManagedPreference(key: .SecureTokenManagementPasswordLocation) as? String ?? "/var/db/.nomadLoginSecureTokenPassword"
        //                        _ = CreateSecureTokenManagementUser(String(describing: secureTokenCreds["username"]!), secureTokenManagementPasswordLocation)
        //                    }
        //                }
        //
        //            // This else if is to maintain historic functionality that the first user logging in with EnableFDE enabled will be given a Secure Token
        //            } else if getManagedPreference(key: .EnableFDE) as? Bool ?? false {
        //                os_log("Historic EnableFDE function enabled, Assigning the user a token then deleting the service account", log: createUserLog, type: .debug)
        //                addSecureToken(shortName, pass, secureTokenCreds["username"] ?? "", secureTokenCreds["password"] ?? "")
        //                let launchPath = "/usr/sbin/sysadminctl"
        //                let args = [
        //                    "-deleteUser",
        //                    "\(String(describing: secureTokenCreds["username"]))",
        //                    "-secure"
        //                ]
        //                _ = cliTask(launchPath, arguments: args, waitForTermination: true)
        //            }
        //        } else {
        //            os_log("SecureToken Credentials inaccessible, failing silently", log: createUserLog, type: .error)
        //        }
        
        os_log("Checking for aliases to add...", log: createUserLog, type: .debug)
        
        if getManagedPreference(key: .AliasUPN) as? Bool ?? false {
            if let upn = getHint(type: .kerberos_principal) as? String {
                os_log("Adding UPN as an alias: %{public}@", log: createUserLog, type: .debug, upn)
                let result = XCredsCreateUser.addAlias(name: shortName, alias: upn.lowercased())
                os_log("Adding UPN result: %{public}@", log: createUserLog, type: .debug, result.description)
            }
        }

        if let aliasHint = getHint(type: .aliasName) as? String {
            if XCredsCreateUser.addAlias(name: shortName, alias: aliasHint)==false {
                os_log("error adding alias", log: createUserLog, type: .debug)
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
        os_log("Checking for available UID", log: createUserLog, type: .debug)
        
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

        let res=cliTask("/usr/sbin/createhomedir -c -u \(user)")

        TCSLogWithMark(res)
//        os_log("Find system locale...", log: createUserLog, type: .debug)
//        let currentLanguage = Locale.current.languageCode ?? "Non_localized"
//        os_log("System language is: %{public}@", log: createUserLog, type: .debug, currentLanguage)
//        let templateName = templateForLang(currentLanguage)
//        let sourceURL = URL(fileURLWithPath: "/System/Library/User Template/" + templateName)
//        let homeDirLocations = ["Desktop", "Downloads", "Documents", "Movies", "Music", "Pictures", "Public"]
//        do {
//            os_log("Initializing the user home directory", log: createUserLog, type: .debug)
//            try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: "/Users/" + user))
//
//            os_log("Copying non-localized folders to new home", log: createUserLog, type: .debug)
//            for location in homeDirLocations {
//                try FileManager.default.copyItem(at: URL(fileURLWithPath: "/System/Library/User Template/Non_localized/\(location)"), to: URL(fileURLWithPath: "/Users/" + user + "/\(location)"))
//            }
//
//            os_log("Copying language template", log: createUserLog, type: .debug)
//            try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: "/Users/" + user))
//        } catch {
//            os_log("Home template copy failed with: %{public}@", log: createUserLog, type: .error, error.localizedDescription)
//        }
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
                os_log("Could not add timestamp", log: createUserLog, type: .error)
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
    
    
//    fileprivate func CreateSecureTokenManagementUser(_ username: String,_ passwordLocation: String) -> Bool{
//
//        // Generating a random password string and assigning that as the password to the user
//        let password = randomString(length: getManagedPreference(key: .SecureTokenManagementPasswordLength) as? Int ?? 16)
//
//        // Checking if the account exists
//        if cliTask("/usr/bin/dscl", arguments: [".", "-list", "/Users"], waitForTermination: true).components(separatedBy: "\n").contains(username){
//            // User already exists, should rotate the password
//            os_log("Secure Token management account exists, rotating password", log: createUserLog, type: .default)
//
//            // Getting the old password
//            let oldPassword = String(data: FileManager.default.contents(atPath: passwordLocation)!, encoding: .ascii)!
//
//            // rotating the password
//            let launchPath = "/usr/sbin/sysadminctl"
//            let args = [
//                "-resetPasswordFor",
//                "\(username)",
//                "-newPassword",
//                "\(password)",
//                "-adminUser",
//                "\(username)",
//                "-adminPassword",
//                "\(oldPassword)"
//            ]
//            _ = cliTask(launchPath, arguments: args, waitForTermination: true)
//
//        } else {
//            os_log("Secure Token management account being created", log: createUserLog, type: .default)
//
//            // Creating the user record with sysadminctl becuase it does the magic that allows it to delegate tokens vs manually creating via dscl
//            var launchPath = "/usr/sbin/sysadminctl"
//            var args = [
//                "-addUser",
//                "\(username)",
//                "-password",
//                "\(password)",
//                "-UID",
//                getManagedPreference(key: .SecureTokenManagementUID) as? String ?? "400",
//                "-fullName",
//                getManagedPreference(key: .SecureTokenManagementFullName) as? String ?? "NoMAD Login",
//                "-home",
//                "/private/var/_nomadlogin",
//                "-admin",
//                "-picture",
//                getManagedPreference(key: .SecureTokenManagementIconPath) as? String ?? "/Library/Security/SecurityAgentPlugins/NoMADLoginAD.bundle/Contents/Resources/NoMADFDEIcon.png"
//            ]
//            _ = cliTask(launchPath, arguments: args, waitForTermination: true)
//
//            // Making the user hiddem
//            launchPath = "/usr/bin/dscl"
//            args = [
//                ".",
//                "-create",
//                "/Users/\(username)",
//                "IsHidden",
//                "1"
//            ]
//            _ = cliTask(launchPath, arguments: args, waitForTermination: true)
//
//        }
//
//        // Saving that password to the password location
//        do {
//            try password.write(toFile: passwordLocation, atomically: true, encoding: String.Encoding.ascii)
//            var attributes = [FileAttributeKey : Any]()
//            attributes[.posixPermissions] = 0o600
//            try FileManager.default.setAttributes(attributes, ofItemAtPath: passwordLocation)
//        } catch {
//            os_log("Error writing password to: %{public}@", log: createUserLog, type: .debug, passwordLocation)
//            return false
//        }
//        return true
//    }
    
}
extension String {
    var oidc_allowed_chars: String {
        var allowed = CharacterSet()
        allowed.formUnion(CharacterSet.alphanumerics)
        allowed.insert(charactersIn: "_#")
        return self.components(separatedBy: allowed.inverted).joined()
    }
}
