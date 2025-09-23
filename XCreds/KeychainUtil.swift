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
            
            
            if (authArray as! [String]).contains("ACLAuthorizationChangeACL") {
                
                TCSLogWithMark("Found ACLAuthorizationChangeACL.")
                
                SecACLSetContents(acl, secApps as CFArray, "" as CFString, prompt)
                continue
            }
            if (authArray as! [String]).contains("ACLAuthorizationDecrypt") {
                
                TCSLogWithMark("Found ACLAuthorizationDecrypt.")
                
                SecACLSetContents(acl, secApps as CFArray, "" as CFString, prompt)
                continue
            }
            
//            if !(authArray as! [String]).contains("ACLAuthorizationPartitionID") {
//                TCSLogWithMark("Found ACLAuthorizationPartitionID.")
//                continue
//            }
            
            
            
        }
        
        
        
//        var secACL:SecACL?
//        let res3 = SecACLCreateWithSimpleContents(secAccess, secApps as CFArray, "XCreds prompt" as CFString, prompt, &secACL)

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
//                var secACL:SecACL?
//
////                let res3 = SecACLCreateWithSimpleContents(secAccess, nil, "XCreds prompt" as CFString, prompt, &secACL)
//                
//                
//                let propertyListObject = ["Partitions":["teamid:UXP6YEHSPW","apple:"]]
//
//                let format: PropertyListSerialization.PropertyListFormat = .xml
//
//                // now serialize it back into a plist
//
//                let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
//
//                // now that all ACLs has been adjusted, we can update the item
//
//                let err = SecACLSetContents(acl, appList, xmlObject!.hexEncodedString() as CFString, prompt)
//
//                if err == 0 {
//                    TCSLogWithMark("SecACLSetContents success")
//                }
//                else {
//                    TCSLogWithMark("error SecACLSetContents")
//                }
                
                
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

        /*
         */

        
        

//

        return secKeychainItem


//        myErr = SecKeychainAddGenericPassword(nil, UInt32(serviceName.count), serviceName, UInt32(accountName.count), accountName,UInt32(strlen(pass.cString(using: .utf8) ?? [])), pass.cString(using: .utf8) ?? [], &myKeychainItem)
//
//
//        return myErr
    }

    func updatePassword(serviceName:String, accountName: String, pass: String, shouldUpdateACL:Bool=false, keychainPassword:String ) -> Bool {
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

//        if shouldUpdateACL==true {
//            if let secKeychainItem = secKeychainItem {
//                TCSLogWithMark("Updating ACL for \(accountName)")
//
//                updateACL(password:pass, keychainItem: secKeychainItem)
//            }
//            else {
//                TCSLogErrorWithMark("ERROR Updating ACL")
//
//                return false
//            }
//            
//        }
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
        @available(macOS, deprecated: 11)
    func updateACL(password:String, keychainItem:SecKeychainItem){
        var myACLs : CFArray? = nil
        var itemAccess: SecAccess? = nil

//        guard let keychainItem = myKeychainItem else {
//            TCSLogWithMark("Keychain item not found")
//            return
//        }
        var err = SecKeychainItemCopyAccess(keychainItem, &itemAccess)

        guard let itemAccess = itemAccess else {
            TCSLogWithMark("item access invalid")
            return
        }

        SecAccessCopyACLList(itemAccess, &myACLs)

        var appList: CFArray? = nil
        var desc: CFString? = nil

        var prompt = SecKeychainPromptSelector()
        var secApps = [ SecTrustedApplication ]()

        var trust : SecTrustedApplication? = nil
        if FileManager.default.fileExists(atPath: "/Applications/XCreds.app", isDirectory: nil) {
            err = SecTrustedApplicationCreateFromPath("/Applications/XCreds.app", &trust)
            if err == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for XCreds.app")

            }
        }
        if FileManager.default.fileExists(atPath: "/Applications/XCreds.app/Contents/Resources/XCreds Login Autofill.app/Contents/PlugIns/XCreds Login Password.appex", isDirectory: nil) {
            err = SecTrustedApplicationCreateFromPath("/Applications/XCreds.app/Contents/Resources/XCreds Login Autofill.app/Contents/PlugIns/XCreds Login Password.appex", &trust)
            if err == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for autofill")

            }
        }
        if FileManager.default.fileExists(atPath: "/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.x86_64.xpc", isDirectory: nil) {
            err = SecTrustedApplicationCreateFromPath("/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.x86_64.xpc", &trust)
            if err == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for authorizationhost")
                
            }
        }
        if FileManager.default.fileExists(atPath: "/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.arm64.xpc", isDirectory: nil) {
            err = SecTrustedApplicationCreateFromPath("/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.arm64.xpc", &trust)
            if err == 0 {
                secApps.append(trust!)
            }
            else {
                TCSLogWithMark("error appending trust for authorizationhost")
                
            }

        }

        for acl in myACLs as! Array<SecACL> {
            SecACLCopyContents(acl, &appList, &desc, &prompt)
            let authArray = SecACLCopyAuthorizations(acl)

            var descr:CFString?
            var appList:CFArray?

            SecACLCopyContents(acl, &appList, &descr, &prompt)
TCSLogWithMark()
            
            if (authArray as! [String]).contains("ACLAuthorizationPartitionID") {
                            TCSLogWithMark("Found ACLAuthorizationPartitionID.")
                            
            }
            
            
            
                
//            if (authArray as! [String]).contains("ACLAuthorizationDecrypt") {
//
//                TCSLogWithMark("Found ACLAuthorizationDecrypt.")
//
//                SecACLSetContents(acl, secApps as CFArray, "" as CFString, prompt)
//                continue
//            }
//
//            if !(authArray as! [String]).contains("ACLAuthorizationPartitionID") {
//                TCSLogWithMark("Found ACLAuthorizationPartitionID.")
//                continue
//            }
//
//
//            // pull in the description that's really a functional plist <sigh>
//            let rawData = Data.init(fromHexEncodedString: desc! as String)
//            var format: PropertyListSerialization.PropertyListFormat = .xml
//
//            var propertyListObject = [ String: [String]]()
//
//            do {
//                propertyListObject = try PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
//            } catch {
//                TCSLogWithMark("No teamid in ACLAuthorizationPartitionID.")
//            }
//            let teamIds = [ "apple:", "teamid:UXP6YEHSPW" ]
//
//            propertyListObject["Partitions"] = teamIds
//
//            // now serialize it back into a plist
//
//            let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
//
//            // now that all ACLs has been adjusted, we can update the item
//
//            err = SecACLSetContents(acl, appList, xmlObject!.hexEncodedString() as CFString, prompt)
//
//            if err == 0 {
//                TCSLogWithMark("SecACLSetContents success")
//            }
//            else {
//                TCSLogWithMark("error SecACLSetContents")
//            }
//
//            // smack it again to set the ACL

            err = SecKeychainItemSetAccess(keychainItem, itemAccess )
            
            if err == 0 {
                TCSLogWithMark("SecKeychainItemSetAccessWithPassword success")
            }
            else {
                
                TCSLogWithMark("error SecKeychainItemSetAccessWithPassword \(err)")
            }



        }
    }
//
//    // return the last expiration date for any certs that match the domain and user
//
//    func findCertExpiration(_ identifier: String, defaultNamingContext: String) -> Date? {
//
//        var matchingCerts = [certDates]()
//        var myCert: SecCertificate? = nil
//        var searchReturn: AnyObject? = nil
//        var lastExpire = Date.distantPast
//
//        // create a search dictionary to find Identitys with Private Keys and returning all matches
//
//        /*
//         @constant kSecMatchIssuers Specifies a dictionary key whose value is a
//         CFArray of X.500 names (of type CFDataRef). If provided, returned
//         certificates or identities will be limited to those whose
//         certificate chain contains one of the issuers provided in this list.
//         */
//
//        // build our search dictionary
//
//        let identitySearchDict: [String:AnyObject] = [
//            kSecClass as String: kSecClassIdentity,
//            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate as String as String as AnyObject,
//
//            // this matches e-mail address
//            //kSecMatchEmailAddressIfPresent as String : identifier as CFString,
//
//            // this matches Common Name
//            //kSecMatchSubjectContains as String : identifier as CFString,
//
//            kSecReturnRef as String: true as AnyObject,
//            kSecMatchLimit as String : kSecMatchLimitAll as AnyObject
//        ]
//
//        myErr = 0
//
//
//        // look for all matches
//
//        myErr = SecItemCopyMatching(identitySearchDict as CFDictionary, &searchReturn)
//
//        if myErr != 0 {
//            return nil
//        }
//
//        let foundCerts = searchReturn as! CFArray as Array
//
//        if foundCerts.count == 0 {
//            return nil
//        }
//
//        for cert in foundCerts {
//
//            myErr = SecIdentityCopyCertificate(cert as! SecIdentity, &myCert)
//
//            if myErr != 0 {
//                return nil
//            }
//
//                    // get the full OID set for the cert
//
//                    let myOIDs : NSDictionary = SecCertificateCopyValues(myCert!, nil, nil)!
//
//            // look at the NT Principal name
//
//            if myOIDs["2.5.29.17"] != nil {
//                let SAN = myOIDs["2.5.29.17"] as! NSDictionary
//                let SANValues = SAN["value"]! as! NSArray
//                for values in SANValues {
//                    let value = values as! NSDictionary
//                    if String(_cocoaString: value["label"]! as AnyObject) == "1.3.6.1.4.1.311.20.2.3" {
//                        if let myNTPrincipal = value["value"] {
//                            // we have an NT Principal, let's see if it's Kerberos Principal we're looking for
//                            TCSLogWithMark("Certificate NT Principal: " + String(describing: myNTPrincipal) )
//                            if String(describing: myNTPrincipal) == identifier {
//TCSLogWithMark("Found cert match")
//
//
//                                                // we have a match now gather the expire date and the serial
//
//                                                let expireOID : NSDictionary = myOIDs["2.5.29.24"]! as! NSDictionary
//                                                let expireDate = expireOID["value"]! as! Date
//
//                                                // this finds the serial
//
//                                                let serialDict : NSDictionary = myOIDs["2.16.840.1.113741.2.1.1.1.3"]! as! NSDictionary
//                                                let serial = serialDict["value"]! as! String
//
//                                                // pack the data up into a certDate
//
//                                                let certificate = certDates( serial: serial, expireDate: expireDate)
//
//                                                if lastExpire.timeIntervalSinceNow < expireDate.timeIntervalSinceNow {
//                                                    lastExpire = expireDate
//                                                }
//
//                                                // append to the list
//
//                                                matchingCerts.append(certificate)
//
//                            } else {
//TCSLogWithMark("Certificate doesn't match current user principal.")
//                            }
//                        }
//
//                    }
//                }
//            }
//
//            }
//        TCSLogWithMark("Found " + String(matchingCerts.count) + " certificates.")
//        TCSLogWithMark("Found certificates: " + String(describing: matchingCerts) )
//        return lastExpire
//    }
}
