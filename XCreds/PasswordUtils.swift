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

enum DSQueryableErrors: Error {
    case notLocalUser
    case multipleUsersFound
}

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

    class func verifyPassword(password:String) -> Bool {
        let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
        do {
            try currentUser?.verifyPassword(password)
        }
        catch {
            return false

        }
        return true
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
    /// `ODNode` to DSLocal for queries and account manipulation.
    public class var localNode: ODNode? {
        do {
            TCSLogWithMark("Finding the DSLocal node")
            return try ODNode.init(session: ODSession.default(), type: ODNodeType(kODNodeTypeLocalNodes))
        } catch {
            TCSLogWithMark("ODError creating local node.")
            return nil
        }
    }

    /// Conviennce function to discover if a shortname has an existing local account.
    ///
    /// - Parameter shortName: The name of the user to search for as a `String`.
    /// - Returns: `true` if the user exists in DSLocal, `false` if not.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    public class func isUserLocal(_ shortName: String) throws -> Bool {
        do {
            _ = try getLocalRecord(shortName)
        } catch DSQueryableErrors.notLocalUser {
            return false
        } catch {
            throw error
        }
        return true
    }

    /// Checks a local username and password to see if they are valid.
    ///
    /// - Parameters:
    ///   - userName: The name of the user to search for as a `String`.
    ///   - userPass: The password for the user being tested as a `String`.
    /// - Returns: `true` if the name and password combo are valid locally. `false` if the validation fails.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error.
    public class func isLocalPasswordValid(userName: String, userPass: String) throws -> Bool {
        do {
            let userRecord = try PasswordUtils.getLocalRecord(userName)
            try userRecord.verifyPassword(userPass)
        } catch {
            let castError = error as NSError
            switch castError.code {
            case Int(kODErrorCredentialsInvalid.rawValue):
                TCSLogWithMark("Tested password for user account: \(userName) is not valid.")
                return false
            default:
                throw error
            }
        }
        return true
    }

    /// Searches DSLocal for an account short name and returns the `ODRecord` for the user if found.
    ///
    /// - Parameter shortName: The name of the user to search for as a `String`.
    /// - Returns: The `ODRecord` of the user if one is found in DSLocal.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    public class func getLocalRecord(_ shortName: String) throws -> ODRecord {
        do {
            TCSLogWithMark("Building OD query for name \(shortName)")
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: shortName,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 0)
            let records = try query.resultsAllowingPartial(false) as! [ODRecord]

            if records.count > 1 {
                TCSLogWithMark("More than one local user found for name.")
                throw DSQueryableErrors.multipleUsersFound
            }
            guard let record = records.first else {
                TCSLogWithMark("No local user found. Passing on demobilizing allow login.")
                throw DSQueryableErrors.notLocalUser
            }
            TCSLogWithMark("Found local user: \(record)")
            return record
        } catch {
            TCSLogWithMark("ODError while trying to check for local user: %{public}@")
            throw error
        }
    }

    /// Finds all local user records on the Mac.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` for every account in DSLocal.
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    public class func getAllLocalUserRecords() throws -> [ODRecord] {
        do {
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: kODMatchAny,
                                         returnAttributes: kODAttributeTypeAllAttributes,
                                         maximumResults: 0)
            return try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            TCSLogWithMark("ODError while finding local users.")
            throw error
        }
    }

    /// Returns all the non-system users on a system above UID 500.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` of all the non-system user accounts in DSLocal.
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    public func getAllNonSystemUsers() throws -> [ODRecord] {
        do {
            let allRecords = try PasswordUtils.getAllLocalUserRecords()
            let nonSystem = try allRecords.filter { (record) -> Bool in
                guard let uid = try record.values(forAttribute: kODAttributeTypeUniqueID) as? [String] else {
                    return false
                }
                return Int(uid.first ?? "") ?? 0 > 500 && record.recordName.first != "_"
            }
            return nonSystem
        } catch {
            TCSLogWithMark("ODError while finding local users.")
            throw error
        }
    }
}
