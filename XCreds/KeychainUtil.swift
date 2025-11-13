//
//  KeychainUtil.swift
//  NoMAD
//
//  Created by Joel Rennich on 8/7/16.
//  Copyright © 2016 Trusource Labs. All rights reserved.
//

// class to manage all keychain interaction

enum KeychainError: Error {
    case notConnected
    case notLoggedIn
    case noPasswordExpirationTime
    case ldapServerLookup
    case ldapNamingContext
    case ldapServerPasswordExpiration
    case ldapConnectionError
    case userPasswordSetDate
    case userHome
    case noStoredPassword
    case storedPasswordWrong
}


import OSLog
import Foundation
import Security

struct certDates {
    var serial : String
    var expireDate : Date
}
struct PasswordItem{
    
    var username: String
    var password: String
    var keychainItem: SecKeychainItem
    
}
class KeychainUtil {

//    var myErr: OSStatus
//    let serviceName = "xcreds"

//    var myKeychainItem: SecKeychainItem?

//    init() {
//        myErr = 0
//    }

  

    // find if there is an existing account password and return it or throw
    @available(macOS, deprecated: 10.10)
    func findPassword(serviceName:String, accountName:String?,keychain:SecKeychain?=nil) -> PasswordItem? {

        var passLength: UInt32 = 0
        var passPtr: UnsafeMutableRawPointer? = nil
        var keychainItem: SecKeychainItem?
        TCSLogWithMark("Finding \(serviceName) in keychain")
        
        var keychainToUse:SecKeychain?
        var userKeychain:SecKeychain?
        
        TCSLogWithMark("find password for account:\(String(describing: accountName)) service:(serviceName)")

        
        if let keychain = keychain {
            os_log("using provided keychain")
            keychainToUse=keychain
        }
        else {
            os_log("using user keychain")

            if SecKeychainCopyDomainDefault(SecPreferencesDomain.user, &userKeychain) != errSecSuccess {
                os_log("error getting user keychain")
                return nil
            }

            if let userKeychain = userKeychain {
                keychainToUse = userKeychain
            }
            else {
                os_log("keychain is nil. returning.")
                return nil
            }
        }
        
        let myErr = SecKeychainFindGenericPassword(keychainToUse, UInt32(serviceName.count), serviceName, UInt32((accountName ?? "").count), accountName, &passLength, &passPtr, &keychainItem)


        if myErr == OSStatus(errSecSuccess) {
            let password = NSString(bytes: passPtr!, length: Int(passLength), encoding: String.Encoding.utf8.rawValue)
            guard let password = password, (password as String).isEmpty == false else {
                return nil
            }
            TCSLogWithMark("\(serviceName) found in keychain")


            var account=""
            if let keychainItem=keychainItem {
                var attributeTags = [SecItemAttr.accountItemAttr.rawValue]
                var formatConstants = [UInt32(CSSM_DB_ATTRIBUTE_FORMAT_STRING)]
                
                var attributeInfo = SecKeychainAttributeInfo(count: 1, tag: &attributeTags, format: &formatConstants)
                
                var attrList: UnsafeMutablePointer<SecKeychainAttributeList>? = nil
                
                let res = SecKeychainItemCopyAttributesAndData(keychainItem, &attributeInfo, nil, &attrList,nil,nil);
                
                let accountAttribute = attrList?.pointee.attr?.pointee
                
                if let data=accountAttribute?.data {
                    account = String(bytesNoCopy: data, length: Int((accountAttribute?.length)!),
                                     encoding: String.Encoding.utf8, freeWhenDone: false)!
                }
                
                
                
                TCSLogWithMark()
                
                
                return PasswordItem(username: account, password: password as String, keychainItem: keychainItem)
            }
            return nil
        } else {
            TCSLogErrorWithMark("\(serviceName) not found in keychain")
            return nil
        }
    }

    func trustedApps() -> [SecTrustedApplication] {
        var trust : SecTrustedApplication? = nil
        var secApps = [ SecTrustedApplication ]()

        if FileManager.default.fileExists(atPath: "/Applications/XCreds.app", isDirectory: nil) {
            let status = SecTrustedApplicationCreateFromPath("/Applications/XCreds.app", &trust)
            if status == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for XCreds.app")

            }
        }
       
        
        if FileManager.default.fileExists(atPath: "/Applications/XCreds.app/Contents/Resources/XCreds Login Autofill.app/Contents/PlugIns/XCreds Login Password.appex", isDirectory: nil) {
            let res = SecTrustedApplicationCreateFromPath("/Applications/XCreds.app/Contents/Resources/XCreds Login Autofill.app/Contents/PlugIns/XCreds Login Password.appex", &trust)
            if res == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for autofill")

            }
        }
        if FileManager.default.fileExists(atPath: "/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.x86_64.xpc", isDirectory: nil) {
            let res = SecTrustedApplicationCreateFromPath("/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.x86_64.xpc", &trust)
            if res == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for authorizationhost")
                
            }
        }
        if FileManager.default.fileExists(atPath: "/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.arm64.xpc", isDirectory: nil) {
            let res = SecTrustedApplicationCreateFromPath("/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.arm64.xpc", &trust)
            if res == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for authorizationhost")
                
            }

        }
        return secApps
    }

    // set the password

    func setPassword(serviceName:String, accountName: String, pass: String, keychainPassword:String, keychain:SecKeychain?=nil) -> SecKeychainItem? {
        
        
        let account = accountName
        let passwordData = pass.data(using: String.Encoding.utf8)!
        var secAccess:SecAccess?
        var keychainItem:CFTypeRef?
        var prompt = SecKeychainPromptSelector()
        var aclArray : CFArray? = nil
        var appList: CFArray? = nil
        var desc: CFString? = nil
        
        var keychainToUse:SecKeychain
        var userKeychain:SecKeychain?
        
        TCSLogWithMark("Setting password for account:\(accountName) service:(serviceName)")

        
        if let keychain = keychain {
            os_log("using provided keychain")
            keychainToUse=keychain
        }
        else {
            os_log("using user keychain")

            if SecKeychainCopyDomainDefault(SecPreferencesDomain.user, &userKeychain) != errSecSuccess {
                os_log("error getting user keychain")
                return nil
            }

            if let userKeychain = userKeychain {

                keychainToUse = userKeychain
            }
            else {
                os_log("keychain is nil. returning.")
                return nil
            }
        }


        TCSLogWithMark("Creating ACL")
        //create the default ACLs as SecAccess so we can modify them
        SecAccessCreate(accountName as CFString, nil, &secAccess)
        
        guard let secAccess = secAccess else {
            TCSLogWithMark("Error setting ACL")
            return nil
        
        }
        
        //In order to not get prompted, the app that are allowed to use the
        // ACLAuthorizationDecrypt operation
        //must be included when the ACLs are created.
        //convert the ACLs to a list and then go through them
        //and modify ACLAuthorizationDecrypt. ACLAuthorizationDecrypt is the right
        //that is needed to give apps access to a password
        //adding the app path is not enough; the team id needs to
        //be added to the partition ACL, but we can't create that ACL.
        //We have create the ACLs and then the partition ACL gets added.
        //We then loop over, find it, and modify it.
        
        //convert opaque secAccess to an array
        SecAccessCopyACLList(secAccess, &aclArray)
        //get a list of the trusted apps to share the password
        let secApps = trustedApps()
         
        //loop over them looking for ACLAuthorizationDecrypt
        for acl in aclArray as! Array<SecACL> {
            SecACLCopyContents(acl, &appList, &desc, &prompt)
            let authArray = SecACLCopyAuthorizations(acl)
            
            //set the apps that are allowed to have access to the password item
            if (authArray as! [String]).contains("ACLAuthorizationDecrypt") {
                
                TCSLogWithMark("Found ACLAuthorizationDecrypt.")
                SecACLSetContents(acl, secApps as CFArray, "" as CFString, prompt)
                continue
            }
        }
                
        let attributes: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrService as String: serviceName,
                                    kSecValueData as String: passwordData,
                                    kSecAttrAccess as String: secAccess as SecAccess,
                                     kSecUseKeychain as String:keychainToUse as Any,
                                    kSecReturnRef as String: true
        ]
        
        TCSLogWithMark("Calling SecItemAdd, returning new keychain item (generic password)")
        let res = SecItemAdd(attributes as CFDictionary, &keychainItem)
        if  res != OSStatus(errSecSuccess)  {
            TCSLogWithMark("Error SecItemAdd: \(res) ")
            return nil
        }
        
        let secKeychainItem = keychainItem as! SecKeychainItem
        var accessControlList: SecAccess? = nil

        
        var err = SecKeychainItemCopyAccess(secKeychainItem, &accessControlList)
        
        guard let accessControlList = accessControlList else {
            
            TCSLogWithMark("invalid accessControlList: \(err)")
            return nil

        }
        //turn the opaque accessControlList to an array of secACLs
        //so we can iterate over them
        SecAccessCopyACLList(accessControlList, &aclArray)

        //iterate over the acls in the array
        //when the acl in the array changes, it changes the items
        //in the accessControlList but doesn't change the
        //access control list in the secKeychainItem until
        //SecKeychainItemSetAccessWithPassword is called
        
        for acl in aclArray as! Array<SecACL> {
            
            //each ACL has one or more auth operations
            //a list of apps that have access to those operations
            //and a prompt selector. the prompt selector is the default
            //since macOS seems to want to prompt on everything regardless
            
            SecACLCopyContents(acl, &appList, &desc, &prompt)
            
            //For this ACL, get the operations that it covers
            
            let authArray = SecACLCopyAuthorizations(acl)
            
            //see if it is ACLAuthorizationPartitionID, which is the
            //ACL that allows access by team id.
            if (authArray as! [String]).contains("ACLAuthorizationPartitionID") {
                TCSLogWithMark("Found ACLAuthorizationPartitionID.")
                
                // pull in the description that is a plist
                let rawData = Data.init(fromHexEncodedString: desc! as String)
                var format: PropertyListSerialization.PropertyListFormat = .xml
                
                var propertyListObject = [ String: [String]]()
                
                do {
                    propertyListObject = try PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
                } catch {
                    TCSLogWithMark("No teamid in ACLAuthorizationPartitionID.")
                }
                let teamIds = [ "apple:", "teamid:UXP6YEHSPW" ]
                
                propertyListObject["Partitions"] = teamIds
                
                // now serialize it back into a plist
                
                let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
                
                // now that all ACLs has been adjusted, we can update the item
                
                err = SecACLSetContents(acl, secApps as CFArray, xmlObject!.hexEncodedString() as CFString, prompt)
                
                if err == 0 {
                    TCSLogWithMark("SecACLSetContents success")
                }
                else {
                    TCSLogWithMark("error SecACLSetContents")
                }
                

            }
            
        }
        
        
        //we really should be using SecKeychainItemSetAccess but it always errors if you change
        //the partition ID.
        
        err = SecKeychainItemSetAccessWithPassword(secKeychainItem, accessControlList, UInt32(strlen(keychainPassword.cString(using: .utf8) ?? [])), keychainPassword.cString(using: .utf8) ?? [] )

        if err == 0 {
            TCSLogWithMark("SecKeychainItemSetAccessWithPassword success")
        }
        else {
            TCSLogWithMark("error SecKeychainItemSetAccessWithPassword: \(err)")
        }

        return secKeychainItem


    }

    func updatePassword(serviceName:String, accountName: String, pass: String, keychainPassword:String, keychain:SecKeychain?=nil) -> Bool {
        let passwordItem = findPassword(serviceName: serviceName, accountName: accountName, keychain: keychain)
        if let passwordItem = passwordItem {
            let _ = deletePassword(keychainItem: passwordItem.keychainItem)
        }
        TCSLogWithMark("setting new password for \(accountName) \(serviceName)")

        let secKeychainItem = setPassword(serviceName: serviceName, accountName: accountName, pass: pass, keychainPassword: keychainPassword,keychain: keychain)
        if secKeychainItem == nil {
            TCSLogErrorWithMark("setting new password FAILURE: accountname:\(accountName)")
            return false
        }
        TCSLogWithMark("setting new password success")
        return true
    }

    // delete the password from the keychain
    @available(macOS, deprecated: 11)
    func deletePassword(keychainItem:SecKeychainItem) -> OSStatus {
        return SecKeychainItemDelete(keychainItem)

    }

    @available(macOS, deprecated: 10.10)
    func clearPasswords(serviceName:String,keychain:SecKeychain?=nil) -> Bool {
        findAndDelete(serviceName: serviceName, accountName: nil, keychain: keychain)
    }
    // convience functions
    @available(macOS, deprecated: 11)
    func findAndDelete(serviceName: String, accountName: String?, keychain:SecKeychain?=nil) -> Bool {
        
        while true {
            guard let passwordItem = findPassword(serviceName: serviceName, accountName:accountName,keychain: keychain) else {
                break
            }
            let res = deletePassword(keychainItem: passwordItem.keychainItem)
            if res != 0  {
                return false
            }
                      

        }
        return true //on password found so don't delete and return true
    }
}
