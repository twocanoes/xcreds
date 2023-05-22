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
    case errorSkipMigration // unable to complete migration
    case fullMigration // perform full migration
    case skipMigration // no need to migrate
    case syncPassword // local password needs to be synced with local
    case userMatchSkipMigration
    case complete // all good
}

// class to handle local checks and migration

class LocalCheckAndMigrate : NSObject, DSQueryable {
    
    var mech: MechanismRecord?
    
    private var user = ""
    private var pass = ""
    
    public var migrationUsers: [String]?
    
    func run(userToCheck: String, passToCheck: String) -> MigrationType {

        user = userToCheck
        pass = passToCheck
        
        let migrate = (getManagedPreference(key: .Migrate) as? Bool ?? false)

        // check local user pass to see if user exists
        
        do {
            if try isLocalPasswordValid(userName: userToCheck, userPass: passToCheck) {
            
                //os_log("Network creds match local creds, nothing to migrate or update.", log: uiLog, type: .default)
                
                if migrate {
                    //os_log("Migrate set, adding migration name hint.", log: uiLog, type: .default)
                    // set the migration hint
                    setHint(type: .migrateUser, hint: userToCheck)
                    return .userMatchSkipMigration
                } else {
                    return .complete
                }
            } else {
                
                //os_log("Local name matches, but not password", log: uiLog, type: .default)
                
                if (getManagedPreference(key: .PasswordOverwriteSilent) as? Bool ?? false) {
                    // set the hint and return complete
                    //os_log("Setting password to be overwritten.", log: uiLog, type: .default)
                    setHint(type: .passwordOverwrite, hint: true)
                    //os_log("Hint set", log: uiLog, type: .debug)
                    return .complete
                } else {
                    return .syncPassword
                }
            }
        } catch DSQueryableErrors.notLocalUser {
            //os_log("User is not a local user", log: uiLog, type: .default)
            
            if migrate {
                getMigrationCandidates()
                
                if migrationUsers?.count ?? 0 < 1 {
                    //os_log("No possible migration candidates, skipping migration", log: uiLog, type: .default)
                    return .skipMigration
                } else {
                    return .fullMigration
                }
            } else {
                return .complete
            }
        } catch {
            //os_log("Unknown migration check error", log: uiLog, type: .default)
            
            return .errorSkipMigration
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
        setHint(type: .migratePass, hint: oldPass)
        return true
    }
}
