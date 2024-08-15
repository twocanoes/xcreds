//
//  KeychainAdd.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 1/30/18.
//  Copyright © 2018 Orchard & Grove Inc. All rights reserved.
//

import Cocoa
import Security

import OpenDirectory
// headless mech to add items to a keychain
class XCredsKeychainAdd : XCredsBaseMechanism {
    
    let fm = FileManager.default
    var username = ""
    var userpass = ""
    let kItemName = "xcreds"
    
    @objc override func run() {
        TCSLogWithMark("XCredsKeychainAdd mech starting")

        // get username and password
        // get reference to user's keychain
        // add items
        var err : OSStatus?
        var userKeychainTemp : SecKeychain?
        var userKeychain: SecKeychain?
        username = usernameContext ?? ""
        userpass = passwordContext ?? ""



        TCSLogWithMark("Getting Home Dir")

        let (uid, home) = checkUIDandHome(name: username)

        TCSLogWithMark("uid: \(uid ?? 9999 )")

        guard let homeDir = home as? NSString else {
            TCSLogErrorWithMark("Unable to get home directory path.")
            allowLogin()
            return
        }

        TCSLogWithMark("checking UID")
        guard let userUID = uid else {
            TCSLogErrorWithMark("Unable to get uid.")
            allowLogin()
            return
        }

        // switch uid to user so we have access to home directory and other things
        TCSLogWithMark()

        seteuid(userUID)
        TCSLogWithMark()

        // check to ensure the keychain is there
        let userKeychainPath = homeDir.appendingPathComponent("Library/Keychains/login.keychain-db")
        TCSLogWithMark("finding path")
        if fm.fileExists(atPath: userKeychainPath) == false {
            // if we're not set to create a keychain, move on
            if getManagedPreference(key: .KeychainCreate) as? Bool == true {
                os_log("No login.keychain-db, creating one", log: "keychainAddLog")
                SecKeychainResetLogin(UInt32(userpass.count), userpass, true)
            } else {
                os_log("No login.keychain-db, skipping KeychainAdd", log: "keychainAddLog", type: .default)
                allowLogin()
                return
            }
        }

        // now test it we can unlock the keychain
        let tempPath = userKeychainPath + Date().timeIntervalSinceNow.description
        TCSLogWithMark("Link old keychain")
        // need to do this on a hardlink to not prevent the keychain reset from working by leaving a handle open
        link(userKeychainPath, tempPath)
        
        TCSLogWithMark("Getting Temp Keychain reference.")

        err = SecKeychainOpen(tempPath, &userKeychainTemp)

        TCSLogWithMark("Unlocking Temp Keychain.")
        
        err = SecKeychainUnlock(userKeychainTemp, UInt32(userpass.count), userpass, true)
        
        // remove the link first
        
        unlink(tempPath)
        
        userKeychainTemp = nil
        
        if err != noErr {
            TCSLogErrorWithMark("Unable to unlock keychain reference.")
            // check if we should reset
            
            if let resetPass = getHint(type: .existingLocalUserPassword) as? String {
                
                TCSLogWithMark("Resetting keychain with migrated user/pass.")
                
                var myKeychain : SecKeychain?
                
                err = SecKeychainOpen(userKeychainPath, &myKeychain)
                
                err = SecKeychainChangePassword(myKeychain, UInt32(resetPass.count), resetPass, UInt32(userpass.count), userpass)
                
                if err != 0 {
                    TCSLogWithMark("Unable to reset keychain with migrated user/pass.")
                    
                }
            }
            else if (getManagedPreference(key: .KeychainReset) as? Bool ?? true ) {
                os_log("Resetting keychain password.", log: "", type: .info)
                clearKeychain(path: homeDir as String)

            }
            else {
                TCSLogErrorWithMark("Keychain is locked, exiting.")
                allowLogin()
                return
            }
        }
        

        // keychain unlock worked, now to get the real one

        TCSLogWithMark("Getting Keychain reference.")

        err = SecKeychainOpen(userKeychainPath, &userKeychain)

        TCSLogWithMark("Unlocking Keychain.")

        err = SecKeychainUnlock(userKeychain, UInt32(userpass.count), userpass, true)

        if err != noErr {
            TCSLogErrorWithMark("error unlocking keychain!")

        }
        let tokenArray = getHint(type: .tokens) as? Array<String>
        let domainName = getHint(type: .noMADDomain) as? String
        let shortName = getHint(type: .user) as? String

        TCSLogWithMark("got shortname of \(shortName ?? "Unknown")")

        if let tokenArray = tokenArray, tokenArray.count>2 {
            TCSLogWithMark("We have tokens, so cloud login")
//            let tokenArray = getHint(type: .tokens) as? Array<String>

//            guard let tokenArray = tokenArray, tokenArray.count>2 else {
//                TCSLogWithMark("no tokens but allowing login")
//                allowLogin()
//                return
//            }

            let xcredsCreds = Creds(accessToken: tokenArray[2], idToken: tokenArray[0], refreshToken: tokenArray[1], password: userpass, jsonDict: Dictionary(), pass: userpass)
            TCSLogWithMark("saving tokens to keychain")
            if TokenManager.saveTokensToKeychain(creds: xcredsCreds, setACL: true, password:userpass )==false {
                TCSLogErrorWithMark("Error saving tokens to keychain")
            }

            allowLogin()
        }
        else if let domainName = domainName, domainName.count>0{
            TCSLogWithMark("AD Login with domain: \(domainName)")

            if let shortName=shortName, KeychainUtil().updatePassword(serviceName: "xcreds local password",accountName:shortName+"@"+domainName, pass: userpass,shouldUpdateACL: true, keychainPassword:userpass) == false {
                TCSLogErrorWithMark("Error Updating password in keychain")

            }
            allowLogin()



//            //        if getManagedPreference(key: .KeychainAddNoMAD) as? Bool == true {
//
//            // keychain unlock worked, now to get the real one
//
////            TCSLogWithMark("Getting Keychain reference.")
////
////            err = SecKeychainOpen(userKeychainPath, &userKeychain)
////
////            TCSLogWithMark("Unlocking Keychain.")
////
////            err = SecKeychainUnlock(userKeychainTemp, UInt32(userpass.count), userpass, true)
//
//            var keychainItem: SecKeychainItem? = nil
//
//            var kItemAccount = usernameContext ?? ""
//
//            if let domain = getManagedPreference(key: .ADDomain) as? String {
//                kItemAccount += "@" + domain.uppercased()
//            }
//
//            let kItemPass = passwordContext
//
//            // set up an item dictionary
//
//            var itemAttrs = [ String : AnyObject ]()
//
//            // get app paths
//
//            //var access : SecAccess? = nil
//
//            var nomadTrust : SecTrustedApplication? = nil
//            //var nomadProTrust : SecTrustedApplication? = nil
//
//            var secApps = [ SecTrustedApplication ]()
//
//            //var accountName = ""
//            //var serviceName = ""
//
//            if fm.fileExists(atPath: "/Applications/NoMAD.app", isDirectory: nil) {
//                err = SecTrustedApplicationCreateFromPath("/Applications/NoMAD.app", &nomadTrust)
//                if err == 0 {
//                    secApps.append(nomadTrust!)
//                }
//            } else if let customNoMADLocation = getManagedPreference(key: .CustomNoMADLocation) as? String {
//                err = SecTrustedApplicationCreateFromPath(customNoMADLocation, &nomadTrust)
//                if err == 0 {
//                    secApps.append(nomadTrust!)
//                }
//            } else {
//                TCSLogWithMark("Checking for NoMAD anywhere on the device.")
//                let ws = NSWorkspace.shared
//                if let customPath = ws.absolutePathForApplication(withBundleIdentifier: "com.trusourcelabs.NoMAD")  {
//                    err = SecTrustedApplicationCreateFromPath(customPath, &nomadTrust)
//                    if err == 0 {
//                        secApps.append(nomadTrust!)
//                    }
//                } else {
//                    TCSLogWithMark("Unable to get custom NoMAD")
//
//                }
//            }
//
//            itemAttrs[kSecAttrType as String] = "genp" as AnyObject
//            //itemAttrs[kSecValueRef as String ] = kItemPass as AnyObject
//            itemAttrs[kSecAttrLabel as String] = "NoMAD" as AnyObject
//            itemAttrs[kSecAttrService as String] = "NoMAD" as AnyObject
//            itemAttrs[kSecAttrAccount as String] = kItemAccount as AnyObject
//
//            // set up the base search dictionary
//
//            var itemSearch: [String:AnyObject] = [
//                kSecClass as String: kSecClassGenericPassword as AnyObject,
//                kSecMatchLimit as String : kSecMatchLimitAll as AnyObject,
//                kSecReturnAttributes as String: true as AnyObject,
//                kSecReturnRef as String : true as AnyObject,
//                ]
//
//            itemSearch[kSecAttrService as String] = kItemName as AnyObject
//            itemSearch[kSecAttrAccount as String] = kItemAccount as AnyObject
//
//
//            // now to create
//
//            err = SecKeychainAddGenericPassword(userKeychain, UInt32(kItemName.count), kItemName, UInt32((kItemAccount.count)), kItemAccount, UInt32((kItemPass?.count)!), kItemPass!, &keychainItem)
//
//            if err != 0 {
//                TCSLogWithMark("Unable to create item")
//
//                // this is most likely because an item is already there, so lets delete then recreate
//
//                err = SecKeychainFindGenericPassword(userKeychain, UInt32(kItemName.count), kItemName, UInt32((kItemAccount.count)), kItemAccount, nil, nil, &keychainItem)
//
//                err = SecKeychainItemDelete(keychainItem!)
//
//                // now to create
//
//                TCSLogWithMark("Creating new keychain item.")
//
//                err = SecKeychainAddGenericPassword(userKeychain, UInt32(kItemName.count), kItemName, UInt32((kItemAccount.count)), kItemAccount, UInt32((kItemPass?.count)!), kItemPass!, &keychainItem)
//
//                if err != 0 {
//                    TCSLogWithMark("Unable to create new keychain item.")
//
//                    allowLogin()
//                    return
//                }
//            }
//
//            // now to set all the ACLs
//
//            // Decode ACL
//
//            var myACLs : CFArray? = nil
//            var itemAccess: SecAccess? = nil
//
//            err = SecKeychainItemCopyAccess(keychainItem!, &itemAccess)
//
//            SecAccessCopyACLList(itemAccess!, &myACLs)
//
//            var appList: CFArray? = nil
//            var desc: CFString? = nil
//
//            var prompt = SecKeychainPromptSelector()
//
//            for acl in myACLs as! Array<SecACL> {
//                SecACLCopyContents(acl, &appList, &desc, &prompt)
//                let authArray = SecACLCopyAuthorizations(acl)
//
//                if (authArray as! [String]).contains("ACLAuthorizationDecrypt") {
//
//                    TCSLogWithMark("Found AUTHORIZATION_CHANGE_ACL.")
//
//                    SecACLSetContents(acl, secApps as CFArray, "" as CFString, prompt)
//                    continue
//                }
//
//                if !(authArray as! [String]).contains("ACLAuthorizationPartitionID") {
//                    continue
//                }
//
//                TCSLogWithMark("Found ACLAuthorizationPartitionID.")
//
//                // pull in the description that's really a functional plist <sigh>
//
//                let rawData = Data.init(fromHexEncodedString: desc! as String)
//                var format: PropertyListSerialization.PropertyListFormat = .xml
//
//                var propertyListObject = [ String: [String]]()
//
//                do {
//                    propertyListObject = try PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
//                } catch {
//                    TCSLogWithMark("No teamid in ACLAuthorizationPartitionID.")
//                }
//
//                let teamIds = [ "teamid:AAPZK3CB24", "teamid:VRPY9KHGX6" ]
//
//                propertyListObject["Partitions"] = teamIds
//
//                // now serialize it back into a plist
//
//                let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
//
//                // now that all ACLs has been adjusted, we can update the item
//
//                err = SecACLSetContents(acl, appList, xmlObject!.hexEncodedString() as CFString, prompt)
//
//                // smack it again to set the ACL
//
//                err = SecKeychainItemSetAccessWithPassword(keychainItem!, itemAccess!, UInt32((kItemPass?.count)!), kItemPass)
//            }
//
//            guard let nomadDefaults = UserDefaults.init(suiteName: "com.trusourcelabs.NoMAD") else {
//                TCSLogWithMark("Could not get NoMAD Pref suite.")
//                allowLogin()
//                return
//            }
//
//            TCSLogWithMark("Setting LastUser pref to \(kItemAccount)")
//            nomadDefaults.set(usernameContext, forKey: "LastUser")

//            if err != 0 {
//                TCSLogWithMark("Error setting up keychain item.")
//            }
        }
        else {
            TCSLogWithMark("Local login so passing through")
            allowLogin()
        }


    }

    // Create keychain item
    
    fileprivate func createKeychainItem() {
        
    }
    
    // OD utils
    
    fileprivate func checkUIDandHome(name: String) -> (uid_t?, String?) {
        os_log("Checking for local username", log: noLoMechlog, type: .debug)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            //            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return (nil, nil)
        }

        if records.count > 1 {
            TCSLogErrorWithMark("More than one record. ")
        }
        do {
            let home = try records.first?.values(forAttribute: kODAttributeTypeNFSHomeDirectory) as? [String] ?? nil
            let uid = try records.first?.values(forAttribute: kODAttributeTypeUniqueID) as? [String] ?? nil

            let uidt = uid_t.init(Double.init((uid?.first) ?? "0")! )
            return ( uidt, home?.first ?? nil)
        } catch {
            TCSLogErrorWithMark("Unable to get home.")
            return (nil, nil)
        }
    }
    func clearKeychain(path: String) {

        // find the hardware UUID to kill the local items keychain
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard let hardwareRaw = IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0) else { return }
        let uuid = hardwareRaw.takeRetainedValue() as? String ?? ""

        if uuid != "" {
            // we have a uuid, now delete the folder
            os_log("Removing local items keychain in order to purge it.", log: "")
            do {
                try fm.removeItem(atPath: path + "/Library/Keychains/" + uuid)
            } catch {
                os_log("Unable to remove Local Items folder.", log: "")
            }
        }

        os_log("Resetting keychain.", log: "")

        SecKeychainResetLogin(UInt32(userpass.count), userpass, true)
    }
}
