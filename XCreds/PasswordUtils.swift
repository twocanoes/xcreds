//
//  PasswordUtils.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa
import SystemConfiguration
import SecurityFoundation
import OpenDirectory

enum PasswordError: Error, CustomStringConvertible {
    case itemNotFound(String)
    case invalidParamater(String)
    case invalidResult(String)
    case unknownError(String)

    var description: String {
        switch self {
        case .itemNotFound(let message): return message
        case .invalidParamater(let message): return message
        case .invalidResult(let message): return message
        case .unknownError(let message): return message
        }
    }
}

class PasswordUtils: NSObject {

    static let currentConsoleUserName: String = NSUserName()
    static let uid: String = String(getuid())

    class func getCurrentConsoleUserRecord() -> ODRecord? {
        // Get ODRecords where record name is equal to the Current Console User's username
        let session = ODSession.default()
        var records = [ODRecord]()
        do {
            //let node = try ODNode.init(session: session, type: UInt32(kODNodeTypeAuthentication))
            let node = try ODNode.init(session: session, type: UInt32(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: UInt32(kODMatchEqualTo), queryValues: currentConsoleUserName, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {

        }


        // We may have gotten multiple ODRecords that match username,
        // So make sure it also matches the UID.
        if ( records != nil ) {
            for case let record in records {
                let attribute = "dsAttrTypeStandard:UniqueID"
                if let odUid = try? String(describing: record.values(forAttribute: attribute)[0]) {
                    if ( odUid == uid) {
                        return record
                    }
                }
            }
        }
        return nil
    }


    class func verifyCurrentUserPassword(password:String) -> Bool {
        let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
        do {
            try currentUser?.verifyPassword(password)
        }
        catch {
            return false

        }
        return true
    }

    class func verifyKeychainPassword(password: String) throws -> Bool  {
        var getDefaultKeychain: OSStatus
        var myDefaultKeychain: SecKeychain?
        var err: OSStatus

        // get the user's default keychain. (Typically login.keychain)
        getDefaultKeychain = SecKeychainCopyDefault(&myDefaultKeychain)
        if ( getDefaultKeychain == errSecNoDefaultKeychain ) {
            throw PasswordError.itemNotFound("Could not find Default Keychain")
        }
        var oldPasswordMutable = password

        err = SecKeychainUnlock(myDefaultKeychain, UInt32(oldPasswordMutable.count), &oldPasswordMutable, true)
        if err != noErr {
            return false
        }
        return true
    }
    static func changeLocalUserAndKeychainPassword(_ oldPassword: String, newPassword1: String, newPassword2: String) throws {
        if (newPassword1 != newPassword2) {
            throw PasswordError.invalidParamater("New passwords do not match.")
        }

        var getDefaultKeychain: OSStatus
        var myDefaultKeychain: SecKeychain?
        var err: OSStatus

        // get the user's default keychain. (Typically login.keychain)
        getDefaultKeychain = SecKeychainCopyDefault(&myDefaultKeychain)
        if ( getDefaultKeychain == errSecNoDefaultKeychain ) {
            throw PasswordError.itemNotFound("Could not find Default Keychain")
        }

        // Test if the keychain password is correct by trying to unlock it.

        var oldPasswordMutable = oldPassword

        err = SecKeychainUnlock(myDefaultKeychain, UInt32(oldPasswordMutable.count), &oldPasswordMutable, true)

        if err != noErr {
            throw PasswordError.invalidResult("Error unlocking default keychain.")
        }

        do {
            try getCurrentConsoleUserRecord()?.changePassword(oldPassword, toPassword: newPassword1)
        } catch  {
            throw PasswordError.unknownError("error changing password")

        }


        err = SecKeychainChangePassword(myDefaultKeychain, UInt32(oldPassword.count), oldPassword, UInt32(newPassword1.count), newPassword1)

        if (err == noErr) {
            return
        } else if ( err == errSecAuthFailed ) {
            return
        } else {
            // If we got any other error, we don't know if the password is good or not because we probably couldn't find the keychain.
            throw PasswordError.unknownError("Unknown error: " + err.description)
        }
    }
}
