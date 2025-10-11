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
@available(macOS, deprecated: 11)
class XCredsKeychainAdd : XCredsBaseMechanism {
    
    let fm = FileManager.default
    var username = ""
    var userpass = ""
    let kItemName = "xcreds"
    
    @objc override func run() {
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ XCredsKeychainAdd mech starting starting mech starting ~~~~~~~~~~~~~~~~~~~")

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
                SecKeychainResetLogin(UInt32(strlen(userpass.cString(using: .utf8) ?? [])), userpass.cString(using: .utf8) ?? [], true)
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
        
        err = SecKeychainUnlock(userKeychainTemp, UInt32(strlen(userpass.cString(using: .utf8) ?? [] )), userpass.cString(using: .utf8) ?? [] , true)

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
                
                err = SecKeychainChangePassword(myKeychain, UInt32(resetPass.count), resetPass, UInt32(strlen(userpass.cString(using: .utf8) ?? [] )), userpass.cString(using: .utf8) ?? [] )

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

        err = SecKeychainUnlock(userKeychain, UInt32(strlen(userpass.cString(using: .utf8) ?? [] )), userpass.cString(using: .utf8) ?? [] , true)


        if err != noErr {
            TCSLogErrorWithMark("error unlocking keychain!")

        }
        let tokenArray = getHint(type: .tokens) as? Array<String>
        let domainName = getHint(type: .noMADDomain) as? String
        let shortName = getHint(type: .user) as? String

        TCSLogWithMark("got shortname of \(shortName ?? "Unknown")")

        if let tokenArray = tokenArray, tokenArray.count>2 {
            TCSLogWithMark("We have tokens, so cloud login")
            XCredsAudit().tokensUpdated(idToken:tokenArray[0])
            let xcredsCreds = Creds(accessToken: tokenArray[2], idToken: tokenArray[0], refreshToken: tokenArray[1], password: userpass, jsonDict: Dictionary())
            TCSLogWithMark("saving tokens to keychain")
            if TokenManager.saveTokensToKeychain(creds: xcredsCreds, keychainPassword:userpass )==false {
                TCSLogErrorWithMark("Error saving tokens to keychain")
            }

            allowLogin()
        }
        else if let domainName = domainName, domainName.count>0{
            TCSLogWithMark("AD Login with domain: \(domainName)")

            if KeychainUtil().updatePassword(serviceName: PrefKeys.password.rawValue,accountName:PrefKeys.password.rawValue, pass: userpass, keychainPassword:userpass) == false {
                TCSLogErrorWithMark("Error Updating password in keychain")

            }
            allowLogin()
        }
        else {
            TCSLogWithMark("Local login so saving password to keychain and passing through")
            if KeychainUtil().updatePassword(serviceName: PrefKeys.password.rawValue,accountName:PrefKeys.password.rawValue, pass: userpass, keychainPassword:userpass) == false {
                TCSLogErrorWithMark("Error Updating password in keychain")

            }
            allowLogin()
        }
    }

    // Create keychain item
    
    fileprivate func createKeychainItem() {
        
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
