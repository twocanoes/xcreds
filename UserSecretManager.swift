//
//  UserSecretManager.swift
//  encryptor
//
//  Created by Timothy Perfitt on 11/20/24.
//

import Foundation
import CryptoKit

public struct UserSecretManager {

    public enum UserSecretManagerError:Error {
        case randomNumberGeneratingError
        case saltLengthError
    }
    public enum SecretKeys: String {
        case adminUsername
        case adminPassword
    }
     var secretKeeper: SecretKeeper
    
    public init(secretKeeper: SecretKeeper) {
        self.secretKeeper = secretKeeper
    }

    func secrets() throws -> Secrets {
        return try secretKeeper.secrets()

    }
    public func updateLocalAdminCredentials(user:SecretKeeperUser) throws{

        let secrets = try secrets()
        secrets.localAdmin=user
        try secretKeeper.saveSecrets(secrets)
    }
    public func localAdminCredentials() throws -> SecretKeeperUser?{
        let secrets = try secrets()
        return secrets.localAdmin

    }
    public func setUIDUser(fullName:String, rfidUID:Data, username:String, password:String, uid:NSNumber, pin:String?) throws {

        //passsword is rfid uid, which is typically max 7 bytes.
        //using key stretching:
        //https://en.wikipedia.org/wiki/Key_stretching
        //the rfid is hashed, and then that result is added to the original rfid and hashed again over and over

        var secretKeeperSecrets = try secrets()
        let (hashedUID,salt) = try PasswordCryptor().hashSecretWithKeyStretchingAndSalt(secret: rfidUID, salt: secretKeeperSecrets.rfidUIDUsers.salt)

        if salt.count<16 {
            throw UserSecretManagerError.saltLengthError
        }
        if let existingUser = try uidUser(uid: rfidUID)  {
            TCSLog("user \(existingUser.username) with rfid already found. replacing.")

            if try removeUIDUser(uid: rfidUID) == false {
                TCSLogWithMark("error removing user")
            }
        }
        if let _ = try uidUser(username: username) {
            TCSLog("user already exists, removing")
            let _ = try removeUIDUser(username: username)
        }
        secretKeeperSecrets = try secrets()
        secretKeeperSecrets.rfidUIDUsers.userDict?[hashedUID] = try SecretKeeperUser(fullName: fullName, username: username, password: password, uid:uid, rfidUID: rfidUID, pin: pin)
        try secretKeeper.saveSecrets(secretKeeperSecrets)
    }

    public func setUIDUsers(_ users:RFIDUsers) throws {
        let secrets = try secrets()
        secrets.rfidUIDUsers=users
        try secretKeeper.saveSecrets(secrets)
    }

    public func uidUser(uid:Data, rfidUsers:RFIDUsers?=nil) throws -> SecretKeeperUser?{

        var rfidUsersLocal:RFIDUsers
        if let rfidUsers = rfidUsers {
            rfidUsersLocal = rfidUsers
        }
        else {
            let secrets = try secrets()
            rfidUsersLocal = secrets.rfidUIDUsers
        }

        let (hashedUID,_) = try PasswordCryptor().hashSecretWithKeyStretchingAndSalt(secret: uid, salt: rfidUsersLocal.salt)

        let userDict = rfidUsersLocal.userDict

        if let existingUser = userDict?[hashedUID]  {
            return existingUser
        }
        return nil

    }
    public func uidUser(username:String) throws -> SecretKeeperUser?{
        let secrets = try secrets()

        let userDict = secrets.rfidUIDUsers.userDict

        for (_,v) in userDict! {
            if v.username.lowercased() == username.lowercased() {
                return v

            }
        }

        return nil

    }

    public func clearUIDUsers() throws {
        let secrets = try secrets()
        secrets.rfidUIDUsers.userDict = [:]
        try secretKeeper.saveSecrets(secrets)
    }
    public func removeUIDUser(uid:Data) throws -> Bool {
        let secrets = try secrets()

        let (hashedUID,_) = try PasswordCryptor().hashSecretWithKeyStretchingAndSalt(secret: uid, salt: secrets.rfidUIDUsers.salt)

        if let _ = try uidUser(uid: uid)  {
            secrets.rfidUIDUsers.userDict?.removeValue(forKey: hashedUID)
            try secretKeeper.saveSecrets(secrets)
            return true
        }
        TCSLogWithMark("No user found with UID \(uid.hexEncodedString())")

        return false
    }
    public func removeUIDUser(username:String) throws -> Bool {
        let secrets = try secrets()
        var removedUser = false
        if let user = secrets.rfidUIDUsers.userDict?.first(where: { (key: Data, value: SecretKeeperUser) in
            value.username.lowercased() == username.lowercased()
        }) {
            secrets.rfidUIDUsers.userDict?.removeValue(forKey: user.key)
            removedUser=true

        }
        if removedUser==true {
            try secretKeeper.saveSecrets(secrets)
        }
        return removedUser
    }
    public func uidUsers() throws-> RFIDUsers {
        let secrets = try secrets()
        return secrets.rfidUIDUsers
    }
}
