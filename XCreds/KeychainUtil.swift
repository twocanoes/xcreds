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
@available(macOS, deprecated: 11)
class KeychainUtil {

//    var myErr: OSStatus
//    let serviceName = "xcreds"

//    var myKeychainItem: SecKeychainItem?

//    init() {
//        myErr = 0
//    }

    // find if there is an existing account password and return it or throw
    @available(macOS, deprecated: 11)
    func findPassword(serviceName:String, accountName:String?) -> PasswordItem? {

        var passLength: UInt32 = 0
        var passPtr: UnsafeMutableRawPointer? = nil
        var keychainItem: SecKeychainItem?
        TCSLogWithMark("Finding \(serviceName) in keychain")
        let myErr = SecKeychainFindGenericPassword(nil, UInt32(serviceName.count), serviceName, 0, nil, &passLength, &passPtr, &keychainItem)


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


    // set the password

    func setPassword(serviceName:String, accountName: String, pass: String, keychainPassword:String) -> SecKeychainItem? {

        TCSLogWithMark("Setting password for account:\(accountName) service:(serviceName)")

        let account = accountName
        let password = pass.data(using: String.Encoding.utf8)!
        var secAccess:SecAccess?
        var trust : SecTrustedApplication? = nil
        var secApps = [ SecTrustedApplication ]()

        var keychainItem:CFTypeRef?
        
        
        if FileManager.default.fileExists(atPath: Bundle.main.bundlePath, isDirectory: nil) {
            let status = SecTrustedApplicationCreateFromPath(Bundle.main.bundlePath, &trust)
            if status == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for XCreds.app")

            }
        }
        
        
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
        
        TCSLogWithMark("Creating ACL")
        SecAccessCreate(accountName as CFString, nil, &secAccess)
        var prompt = SecKeychainPromptSelector()
        guard let secAccess = secAccess else {
            TCSLogWithMark("Error setting ACL")
            return nil
        
        }
        var myACLs : CFArray? = nil

        SecAccessCopyACLList(secAccess, &myACLs)
        var appList: CFArray? = nil
        var desc: CFString? = nil

        for acl in myACLs as! Array<SecACL> {
            SecACLCopyContents(acl, &appList, &desc, &prompt)
            let authArray = SecACLCopyAuthorizations(acl)
            
            
            if (authArray as! [String]).contains("ACLAuthorizationDecrypt") {
                
                TCSLogWithMark("Found ACLAuthorizationDecrypt.")
                
                SecACLSetContents(acl, secApps as CFArray, "" as CFString, prompt)
                continue
            }
        }
        


        SecAccessCopyACLList(secAccess, &myACLs)

        for acl in myACLs as! Array<SecACL> {
            SecACLCopyContents(acl, &appList, &desc, &prompt)
            let authArray = SecACLCopyAuthorizations(acl)
            print(authArray)
            
        }
        
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrService as String: serviceName,
                                    kSecValueData as String: password,
                                    kSecAttrAccess as String: secAccess as SecAccess,
                                    kSecReturnRef as String: true
        ]
        TCSLogWithMark("Calling SecItemAdd")

        let res = SecItemAdd(query as CFDictionary, &keychainItem)
        if  res != OSStatus(errSecSuccess)  {
            TCSLogWithMark("Error SecItemAdd: \(res) ")
            return nil
        }
        TCSLogWithMark("Returning keychain item")
      
        let secKeychainItem = keychainItem as! SecKeychainItem

//        let res2 = SecKeychainItemSetAccess(secKeychainItem, secAccess )
        var itemAccess: SecAccess? = nil

        var err = SecKeychainItemCopyAccess(secKeychainItem, &itemAccess)
        SecAccessCopyACLList(itemAccess!, &myACLs)

        for acl in myACLs as! Array<SecACL> {
            SecACLCopyContents(acl, &appList, &desc, &prompt)
            let authArray = SecACLCopyAuthorizations(acl)
            print(authArray)
            if (authArray as! [String]).contains("ACLAuthorizationPartitionID") {
                TCSLogWithMark("Found ACLAuthorizationPartitionID.")
                
                // pull in the description that's really a functional plist <sigh>
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
                

                err = SecKeychainItemSetAccessWithPassword(secKeychainItem, itemAccess, UInt32(strlen(keychainPassword.cString(using: .utf8) ?? [])), keychainPassword.cString(using: .utf8) ?? [] )
            }
        }


        return secKeychainItem


    }

    func updatePassword(serviceName:String, accountName: String, pass: String, keychainPassword:String ) -> Bool {
        let passwordItem = findPassword(serviceName: serviceName, accountName: accountName)
        if let passwordItem = passwordItem {
            TCSLogWithMark("Deleting password")
            let _ = deletePassword(keychainItem: passwordItem.keychainItem)
        }
        TCSLogWithMark("setting new password for \(accountName) \(serviceName)")

        let secKeychainItem = setPassword(serviceName: serviceName, accountName: accountName, pass: pass, keychainPassword: keychainPassword)
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

    // convience functions
    @available(macOS, deprecated: 11)
    func findAndDelete(serviceName: String, accountName: String) -> Bool {
        if let passwordItem = findPassword(serviceName: serviceName, accountName:accountName) {
            if ( deletePassword(keychainItem: passwordItem.keychainItem) == 0 ) {
                return true
            } else {
                return false
            }
        }
        return true //on password found so don't delete and return true
    }
}
