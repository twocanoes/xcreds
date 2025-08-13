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

//enum DSQueryableErrors: Error {
//    case notLocalUser
//    case multipleUsersFound
//}

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
enum PasswordVerificationResult {
    case success
    case incorrectPassword
    case accountDoesNotExist
    case accountLocked
    case other(String)
}


struct SecureTokenCredential {

    var username:String
    var password:String
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

        for case let record in records {
            let attribute = "dsAttrTypeStandard:UniqueID"
            if let odUid = try? String(describing: record.values(forAttribute: attribute)[0]) {
                if ( odUid == uid) {
                    return record
                }
            }
        }

        return nil
    }
    class func GetSecureTokenUserList() -> [String] {
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

    
//    class func verifyUser(name: String, auth: String) -> Bool {
//        os_log("Finding user record", log: noLoMechlog, type: .debug)
//        TCSLogWithMark("searching for user \(name) and password with count \(auth.count)")
//        var records = [ODRecord]()
//        let odsession = ODSession.default()
//        var isValid = false
//        do {
//            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
//            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
//            records = try query.resultsAllowingPartial(false) as! [ODRecord]
//            let result = isLocalPasswordValid(userName: name, userPass: auth)
//            isValid = ((try records.first?.verifyPassword(auth)) != nil)
//        } catch {
//            let errorText = error.localizedDescription
//            TCSLogErrorWithMark("ODError while trying to check for local user: \(errorText)")
//            return false
//        }
//        return isValid
//    }

//    class func verifyPassword(password:String) -> Bool {
//        let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
//        do {
//            try currentUser?.verifyPassword(password)
//        }
//        catch {
//            return false
//
//        }
//        return true
//    }
//
//    class func verifyCurrentUserPassword(password:String) -> Bool {
//        let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
//        do {
//            try currentUser?.verifyPassword(password)
//        }
//        catch {
//            return false
//
//        }
//        return true
//    }

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
    static func changeLocalUserAndKeychainPassword(_ oldPassword: String, newPassword: String) throws {


        TCSLogWithMark()
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
            try getCurrentConsoleUserRecord()?.changePassword(oldPassword, toPassword: newPassword)
        } catch  {
            throw PasswordError.unknownError("error changing password: \(error)")

        }


        err = SecKeychainChangePassword(myDefaultKeychain, UInt32(oldPassword.count), oldPassword, UInt32(newPassword.count), newPassword)

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
    public class func doesUserHomeExist(_ name: String) throws -> Bool {
        // first get the user record

        os_log("Checking for existing home directory", log: noLoMechlog, type: .debug)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return true
        }

        os_log("Record search returned", log: noLoMechlog, type: .info)

        if records.isEmpty {
            os_log("No user found to delete, success!", log: noLoMechlog, type: .debug)
            return true
        } else if records.count > 1 {
            os_log("Multiple users found, failing local user removal", log: noLoMechlog, type: .info)
            return false
        }

        if let homePaths = records.first?.value(forKey: kODAttributeTypeNFSHomeDirectory) as? [String] {

            os_log("Home path found", log: noLoMechlog, type: .info)

            let fm = FileManager.default

            if let homePath = homePaths.first {
                if fm.fileExists(atPath: homePath) {
                    os_log("Home is: %{public}@", log: noLoMechlog, type: .info, homePath)
                    return true

                } else {
                    return false
                }
            }
        }
        return false
    }


    /// Checks a local username and password to see if they are valid.
    ///
    /// - Parameters:
    ///   - userName: The name of the user to search for as a `String`.
    ///   - userPass: The password for the user being tested as a `String`.
    /// - Returns: `true` if the name and password combo are valid locally. `false` if the validation fails.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error.
    public class func isLocalPasswordValid(userName: String, userPass: String) -> PasswordVerificationResult {
        do {
            TCSLogWithMark("getting local record")
            let userRecord = try PasswordUtils.getLocalRecord(userName)
//            TCSLogWithMark("Checking if password is allowed")
//            try userRecord.passwordChangeAllowed(userPass)
            TCSLogWithMark("checking password")
            try userRecord.verifyPassword(userPass)
            TCSLogWithMark("checking password done, returning success")
            return .success

        } catch {
            let castError = error as NSError
            switch castError.code {
            case Int(kODErrorCredentialsInvalid.rawValue):
                TCSLogWithMark("Tested password for user account: \(userName) is not valid.")
                return .incorrectPassword
            case Int(kODErrorCredentialsAccountNotFound.rawValue):
                TCSLogWithMark("No local account for user: \(userName) is not valid.")
                return .accountDoesNotExist
            case Int(kODErrorCredentialsAccountLocked.rawValue):
                TCSLogWithMark("No Account for user: \(userName) is not locked.")
                return .accountLocked

            case Int(kODErrorCredentialsAccountTemporarilyLocked.rawValue):
                TCSLogWithMark("No local account for user: \(userName) is not valid. Local account temporarily locked. Please wait a bit and try again.")
                return .accountLocked

            case Int(kODErrorCredentialsAccountDisabled.rawValue):
                TCSLogWithMark("No local account for user: \(userName) is not valid. Local account disabled. Please wait a bit and try again.")
                return .accountLocked


            case Int(kODErrorCredentialsMethodNotSupported.rawValue):
                TCSLogWithMark("credential type not supported: \(userName).")
                return .other("credential type not supported")


            default:
                TCSLogWithMark("throw error:\(error.localizedDescription):\(castError.code)")
                return .accountDoesNotExist
            }
        }

    }

    func kerberosPrincipalFromCurrentLoggedInUser() -> String?  {
        guard let user = try? PasswordUtils.getLocalRecord(getConsoleUser()),
              let kerbPrincArray = user.value(forKey: "dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal") as? Array <String>,
              let kerbPrinc = kerbPrincArray.first else
        {
            return nil
        }
        return kerbPrinc
    }

    public class func resolveName(_ name:String) throws -> String{

        var record:ODRecord
        do{

            record = try getLocalRecord(name)

        }
        catch {
            record = try getLocalRecord(fullName: name)

        }
        return record.recordName

    }
    public class func getLocalRecord(fullName: String) throws -> ODRecord {
        do {
            TCSLogWithMark("Building OD query for name \(fullName)")
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeFullName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: fullName,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 0)
            let records = try query.resultsAllowingPartial(false) as! [ODRecord]

            if records.count > 1 {
                TCSLogErrorWithMark("More than one local user found for name.")
                throw DSQueryableErrors.multipleUsersFound
            }
            guard let record = records.first else {
                TCSLogInfoWithMark("No local user found. Passing on demobilizing allow login.")
                throw DSQueryableErrors.notLocalUser
            }
            TCSLogWithMark("Found local user: \(record)")
            return record
        } catch {
            TCSLogErrorWithMark("ODError while trying to check for local user: \(error.localizedDescription)")
            throw error
        }
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
                TCSLogErrorWithMark("More than one local user found for name.")
                throw DSQueryableErrors.multipleUsersFound
            }
            guard let record = records.first else {
                TCSLogInfoWithMark("No local user found. Passing on demobilizing allow login.")
                throw DSQueryableErrors.notLocalUser
            }
            TCSLogWithMark("Found local user: \(record)")
            return record
        } catch {
            TCSLogErrorWithMark("ODError while trying to check for local user: \(error.localizedDescription)")
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
