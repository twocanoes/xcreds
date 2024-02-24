//
//  LocalCheckAndMigrate.swift
//  JamfConnectLogin
//
//  Created by Joel Rennich on 2/19/19.
//  Copyright © 2019 Jamf Inc. All rights reserved.
//

import Foundation
import OpenDirectory

enum MigrationType {
    case errorSkipMigration(String) // unable to complete migration
    case fullMigration // perform full migration
    case skipMigration // no need to migrate
    case syncPassword // local password needs to be synced with local
//    case mappedUserFound(ODRecord)
    case userMatchSkipMigration
    case complete // all good
}

// class to handle local checks and migration

class LocalCheckAndMigrate : NSObject, DSQueryable {
    
    var mech: MechanismRecord?
    var delegate: XCredsMechanismProtocol?

    private var user = ""
    private var pass = ""
    
    public var migrationUsers: [String]?
    var isInUserSpace = false

    func migrationTypeRequired(userToCheck: String, passToCheck: String, kerberosPrincipalName:String?) -> MigrationType {

        TCSLogWithMark()
        user = userToCheck
        pass = passToCheck
        var user = userToCheck

        //if we are in userspace, use the console user. If there not and there is a mapped user acccount with a kerb pricipal name in the DS record, use that. Otherwise, just keep on with the user passed in.
        if isInUserSpace == true {
            let consoleUser = getConsoleUser()
            user=consoleUser
        }

        else
        {
            if let kerberosPrincipalName = kerberosPrincipalName, let foundRecord = try? getUserRecord(kerberosPrincipalNameToFind: kerberosPrincipalName) {
            user = foundRecord.recordName
        }
    }
        let shouldPromptToMigrate = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldPromptForMigration.rawValue)

        // check local user pass to see if user exists
        
        do {
            if try isLocalPasswordValid(userName: user, userPass: passToCheck) {

                TCSLogWithMark("Network creds match local creds, nothing to migrate or update.")
                return .userMatchSkipMigration

            } else {
                
                TCSLogWithMark("Local name matches, but not password")
                
                if DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue) != nil &&
                    DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue) != nil &&
                    getManagedPreference(key: .PasswordOverwriteSilent) as? Bool ?? false  && isInUserSpace == false {
                    TCSLogWithMark("Set to write keychain silently and we have admin. Skipping.")
                    TCSLogWithMark("Setting password to be overwritten.")
                    delegate?.setHint(type: .passwordOverwrite, hint: true)
                    TCSLogWithMark("Hint set")
                    return .complete
                } else {
                    TCSLogWithMark("setting to sync password")
                    return .syncPassword
                }
            }
        } catch DSQueryableErrors.notLocalUser {
            TCSLogWithMark("User is not a local user")
            
            if shouldPromptToMigrate == false {
                return .complete
            }

            TCSLogWithMark("prompting to migrate set. checking for local accounts as candidates")
            //                getMigrationCandidates()
            let standardUsers = try? getAllLocalUserRecords()
            guard let standardUsers = standardUsers, standardUsers.count>0 else {
                return .skipMigration
            }
            return .fullMigration

        } catch {
            TCSLogWithMark("Unknown migration check error. skipping migration:\(error.localizedDescription)")
            return .errorSkipMigration(error.localizedDescription)
        }
    }
    
    fileprivate func getMigrationCandidates() {
        do {
            if let hiddenMigrationUsers = getManagedPreference(key: .MigrateUsersHide) as? [String]  {
                migrationUsers = try findNoMADMigrationCandidates(excludeList: hiddenMigrationUsers)
            } else {
                //os_log("No users are hidden from migration.", log: uiLog, type: .default)
                migrationUsers = try findNoMADMigrationCandidates()
            }
        } catch NoMADQueryErrors.noMigrationCandidates {
            //os_log("No local users to possibly migrate.", log: uiLog, type: .default)
        } catch {
            let errorText = error.localizedDescription
            //os_log("Error while determining migration candidate users: %{public}@", log: uiLog, type: .error, errorText)
        }
    }
    
    func syncPass(oldPass: String) -> Bool {

        var userRecord: ODRecord?
        
        do {
            userRecord = try getLocalRecord(user)
            try userRecord?.changePassword(oldPass, toPassword: pass)
        } catch {
            if userRecord == nil {
                //os_log("Unable to obtain local user record.", log: uiLog, type: .default)
            } else {
                //os_log("Unable to change local user password.", log: uiLog, type: .default)
            }
            return false
        }
        
        //os_log("Local password changed.", log: uiLog, type: .default)
        delegate?.setHint(type: .existingLocalUserPassword, hint: oldPass)
        return true
    }
}
