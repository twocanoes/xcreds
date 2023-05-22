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
    public var localNode: ODNode? {
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
    public func isUserLocal(_ shortName: String) throws -> Bool {
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
    public func isLocalPasswordValid(userName: String, userPass: String) throws -> Bool {
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

    /// Searches DSLocal for an account short name and returns the `ODRecord` for the user if found.
    ///
    /// - Parameter shortName: The name of the user to search for as a `String`.
    /// - Returns: The `ODRecord` of the user if one is found in DSLocal.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    public func getLocalRecord(_ shortName: String) throws -> ODRecord {
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
    public func getAllLocalUserRecords() throws -> [ODRecord] {
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

    /// Returns all the non-system users on a system above UID 500.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` of all the non-system user accounts in DSLocal.
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    public func getAllNonSystemUsers() throws -> [ODRecord] {
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
}
