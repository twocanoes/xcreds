//
//  DSQueryable.swift
//  NoMADLogin-AD
//
//  Created by Josh Wisenbaker on 8/20/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import OpenDirectory

enum DSQueryableResults {
    case localUser
}

enum DSQueryableErrors: Error {
    case notLocalUser
    case multipleUsersFound
}

/// The `DSQueryable` protocol allows adopters to easily search and manipulate the DSLocal node of macOS.
public protocol DSQueryable {}

// MARK: - Implimentations for DSQuerable protocol
public extension DSQueryable {

    /// `ODNode` to DSLocal for queries and account manipulation.
    var localNode: ODNode? {
        do {
            os_log("Finding the DSLocal node", type: .debug)
            return try ODNode.init(session: ODSession.default(), type: ODNodeType(kODNodeTypeLocalNodes))
        } catch {
            os_log("ODError creating local node.", type: .error, error.localizedDescription)
            return nil
        }
    }

    /// Conviennce function to discover if a shortname has an existing local account.
    ///
    /// - Parameter shortName: The name of the user to search for as a `String`.
    /// - Returns: `true` if the user exists in DSLocal, `false` if not.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    func isUserLocal(_ shortName: String) throws -> Bool {
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
    func isLocalPasswordValid(userName: String, userPass: String) throws -> Bool {
        do {
            let userRecord = try getLocalRecord(userName)
            try userRecord.verifyPassword(userPass)
        } catch {
            let castError = error as NSError
            switch castError.code {
            case Int(kODErrorCredentialsInvalid.rawValue):
                os_log("Tested password for user account: %{public}@ is not valid.", type: .default, userName)
                return false
            default:
                throw error
            }
        }
        return true
    }


    /// Searches DSLocal for an account short name and returns the `ODRecord` for the group if found.
    ///
    /// - Parameter name: The name of the group to search for as a `String`.
    /// - Returns: The `ODRecord` of the group if one is found in DSLocal.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    func getLocalGroupRecord(_ name: String) throws -> ODRecord {
        do {
            os_log("Building OD query for name %{public}@", type: .default, name)
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeGroups,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: name,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 1)
            let records = try query.resultsAllowingPartial(false) as! [ODRecord]

            if records.count > 1 {
                os_log("More than one local group found for name.", type: .default)
                throw DSQueryableErrors.multipleUsersFound
            }
            guard let record = records.first else {
                os_log("No local group found.", type: .default)
                throw DSQueryableErrors.notLocalUser
            }
//            os_log("Found local user: %{public}@", record)
            return record
        } catch {
            os_log("ODError while trying to check for local user: %{public}@", type: .error, error.localizedDescription)
            throw error
        }
    }


    /// Searches DSLocal for an account short name and returns the `ODRecord` for the user if found.
    ///
    /// - Parameter shortName: The name of the user to search for as a `String`.
    /// - Returns: The `ODRecord` of the user if one is found in DSLocal.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    func getLocalRecord(_ shortName: String) throws -> ODRecord {
        do {
            os_log("Building OD query for name %{public}@", type: .default, shortName)
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: shortName,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 0)
            let records = try query.resultsAllowingPartial(false) as! [ODRecord]

            if records.count > 1 {
                os_log("More than one local user found for name.", type: .default)
                throw DSQueryableErrors.multipleUsersFound
            }
            guard let record = records.first else {
                os_log("No local user found. Passing on demobilizing allow login.", type: .default)
                throw DSQueryableErrors.notLocalUser
            }
//            os_log("Found local user: %{public}@", record)
            return record
        } catch {
            os_log("ODError while trying to check for local user: %{public}@", type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Finds all local user records on the Mac.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` for every account in DSLocal.
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    func getAllLocalUserRecords() throws -> [ODRecord] {
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
            os_log("ODError while finding local users.", type: .error)
            throw error
        }
    }
    /// Finds OIDC User with specified iss and sub.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` for  account in DSLocal
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    func getUserRecord(sub:String, iss:String) throws -> ODRecord {
        do {
            os_log("getting non system users.", type: .info)

            let allRecords = try getAllNonSystemUsers()
            os_log("filtering", type: .info)

            let matchingRecords = allRecords.filter { (record) -> Bool in
                guard let issValue = try? record.values(forAttribute: "dsAttrTypeNative:_xcreds_oidc_iss") as? [String] else {
                    return false
                }
                guard let subValue = try? record.values(forAttribute: "dsAttrTypeNative:_xcreds_oidc_sub") as? [String] else {
                    return false
                }

                os_log("checking \(issValue) \(subValue)", type: .info)

                return issValue.first == iss && subValue.first == sub
            }
            guard let userRecord = matchingRecords.first else {
                os_log("no users match iss \(iss) and sub \(sub)", type: .info)

                throw DSQueryableErrors.notLocalUser
            }
            return userRecord
        } catch {
            os_log("ODError while finding local users.", type: .error)
            throw error
        }
    }
    func getUserRecord(kerberosPrincipalNameToFind:String) throws -> ODRecord {
        do {
            os_log("getting non system users.", type: .info)

            let allRecords = try getAllNonSystemUsers()
            os_log("filtering", type: .info)

            let matchingRecords = allRecords.filter { (record) -> Bool in
                guard let foundKerberosPrincipal = try? record.values(forAttribute: "dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal") as? [String] else {
                    return false
                }

                os_log("checking \(foundKerberosPrincipal)", type: .info)

                return foundKerberosPrincipal.first == kerberosPrincipalNameToFind
            }
            guard let userRecord = matchingRecords.first else {
                TCSLogWithMark("no users match \(kerberosPrincipalNameToFind)")

                throw DSQueryableErrors.notLocalUser
            }
            return userRecord
        } catch {
            os_log("ODError while finding local users.", type: .error)
            throw error
        }
    }

    /// Returns all the non-system users on a system above UID 500.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` of all the non-system user accounts in DSLocal.
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    ///
    func getAllNonSystemUsers() throws -> [ODRecord] {
        do {
            let allRecords = try getAllLocalUserRecords()
            let nonSystem = try allRecords.filter { (record) -> Bool in
                guard let uid = try record.values(forAttribute: kODAttributeTypeUniqueID) as? [String] else {
                    return false
                }
                return Int(uid.first ?? "") ?? 0 > 500 && record.recordName.first != "_"
            }
            return nonSystem
        } catch {
            os_log("ODError while finding local users.", type: .error)
            throw error
        }
    }

    func isAdmin(_ user:ODRecord) -> Bool {
        let adminGroup = try? getLocalGroupRecord("admin")
        do{
            if let adminGroup = adminGroup {
                try adminGroup.isMemberRecord(user)
                return true
            }
        }
        catch {
        }
        return false

    }

    func makeAdmin(_ user:ODRecord) -> Bool {
        do {
            os_log("Find the administrators group",  type: .debug)
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeGroups,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: "admin",
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 1)
            let results = try query.resultsAllowingPartial(false) as! [ODRecord]
            let adminGroup = results.first

            os_log("Adding user to administrators group", type: .debug)
            
            try adminGroup?.addMemberRecord(user)
            try? user.setValue("1", forAttribute: "dsAttrTypeNative:_xcreds_promoted_to_admin")


        } catch {
            let errorText = error.localizedDescription
            os_log("Unable to add user to administrators group: %{public}@", type: .error, errorText)
            return false
        }
        return true
    }
    func removeAdmin(_ user:ODRecord) -> Bool {
        do {
            if try getAllAdminUsers().count<2 {
                TCSLogError("Will not remove last admin!!")
                return false
            }

        }
        catch {
            TCSLogErrorWithMark("Error when getting all admin users")
            return false
        }
        if isAdmin(user)==false { //user is not an admin already
            return true
        }
        do {
            os_log("Find the administrators group",  type: .debug)
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeGroups,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: "admin",
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 1)
            let results = try query.resultsAllowingPartial(false) as! [ODRecord]
            let adminGroup = results.first

            os_log("Remove user to administrators group", type: .debug)
            try adminGroup?.removeMemberRecord(user)

        } catch {
            let errorText = error.localizedDescription
            os_log("Unable to add user to administrators group: %{public}@", type: .error, errorText)
            return false
        }
        return true
    }
    func getAllStandardUsers() throws -> [ODRecord] {
            let allRecords = try getAllNonSystemUsers()
            let nonSystem = allRecords.filter { (record) -> Bool in


                let adminGroup = try? getLocalGroupRecord("admin")

                do{

                    if let adminGroup = adminGroup {
                        try adminGroup.isMemberRecord(record)
                        return false
                    }
                }
                catch {

                }

                return true
            }
        return nonSystem
    }
    func getAllAdminUsers() throws -> [ODRecord] {
            let allRecords = try getAllNonSystemUsers()
            let nonSystemAdminUsers = try allRecords.filter { (record) -> Bool in
                let adminGroup = try? getLocalGroupRecord("admin")
                do{

                    if let adminGroup = adminGroup {
                        try adminGroup.isMemberRecord(record)
                        return true
                    }
                }
                catch {
                    TCSLog("error when looking for admin group membership")
                    throw error
                }

                return true
            }
        return nonSystemAdminUsers
    }

}
