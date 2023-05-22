//
//  DS+AD.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 9/20/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//
import OpenDirectory

enum NoMADQueryErrors: Error {
    case noMigrationCandidates
}

// MARK: - NoMAD extensions for the DSQueryable Protocol.
extension DSQueryable {
    /// Check to see if a given local user has the `kODAttributeOktaUser` set on their account.
    ///
    /// - Parameter shortName: The shortname of the user to check as a `String`.
    /// - Returns: `true` if the user has an Okta attribute. Otherwise `false`.
    /// - Throws: A `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error.
    public func checkForNoMADUser(_ shortName: String) throws -> Bool {
        os_log("Checking for AD username", type: .default)
        do {
            let userRecord = try getLocalRecord(shortName)
            
            let names = try userRecord.values(forAttribute: kODAttributeADUser)
            if names.isEmpty {
                return false
            }
            return true
        } catch DSQueryableErrors.notLocalUser {
            return false
        } catch {
            throw error
        }
    }

    /// Search in DSLocal and find any potential migration users.
    ///
    /// - Parameter excludeList: An optional `Array` of `String` values to exclude from the candidate list. These are typically set in the `.MigrateUsersHide` preference key.
    /// - Returns: The shortnames of the users to offer for Okta migration in an `Array` of `String` values.
    /// - Throws: A `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error. Throws `NoMADQueryErrors.noMigrationCandidates` if no results are found.
    public func findNoMADMigrationCandidates(excludeList: [String] = [String]()) throws -> [String] {
        do {
            os_log("Checking for NoMAD migration users.", type: .default)
            var candidates = [String]()
            os_log("Getting all user records.", type: .default)
            let records = try getAllNonSystemUsers()
            os_log("Filtering records", type: .default)
            let filtered = try records.filter({ (record) -> Bool in
                if excludeList.contains(record.recordName) {
                    os_log("User is exluded", type: .default)
                    return false
                }
                if try checkForNoMADUser(record.recordName) {
                    os_log("User has a NoMAD Attribute", type: .default)
                    return false
                }
                return true
            })
            for record in filtered {
                candidates.append(record.recordName)
            }
            if candidates.isEmpty {
                throw NoMADQueryErrors.noMigrationCandidates
            }
            return candidates
        } catch {
            throw error
        }
    }
}
