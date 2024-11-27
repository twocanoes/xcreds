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
        try secretKeeper.addSecrets(secrets)
    }
    public func localAdminCredentials() throws -> SecretKeeperUser?{
        let secrets = try secrets()
        return secrets.localAdmin

    }
    public func updateUIDUser(fullName:String, rfidUID:Data, username:String, password:String, uid:NSNumber) throws {

        //passsword is rfid uid, which is typically max 7 bytes.
        //using key stretching:
        //https://en.wikipedia.org/wiki/Key_stretching
        //the rfid is hashed, and then that result is added to the original rfid and hashed again over and over
        //the

        let secrets = try secrets()
        let (hashedUID,salt) = try PasswordCryptor().hashSecretWithKeyStretchingAndSalt(secret: rfidUID, salt: nil)

        if salt.count<16 {
            throw UserSecretManagerError.saltLengthError
        }
        secrets.rfidUIDUsers.salt = salt
        secrets.rfidUIDUsers.userDict?[hashedUID] = try SecretKeeperUser(fullName: fullName, username: username, password: password, uid:uid, rfidUID: rfidUID)
        try secretKeeper.addSecrets(secrets)
    }

    public func setUIDUsers(_ users:RFIDUsers) throws {
        let secrets = try secrets()
        secrets.rfidUIDUsers=users
        try secretKeeper.addSecrets(secrets)
    }

//    public func uidUser(uid:Data) throws -> SecretKeeperUser?{
//        let secrets = try secrets()
//        let hashedUID=Data(SHA256.hash(data: uid))
//
//        let uidUsers = secrets.uidUsers
//        return uidUsers.userDict?[hashedUID]
//    }

    public func clearUIDUsers() throws {
        let secrets = try secrets()
        secrets.rfidUIDUsers.userDict = [:]
        try secretKeeper.addSecrets(secrets)
    }

    public func uidUsers() throws-> RFIDUsers {
        let secrets = try secrets()
        return secrets.rfidUIDUsers
    }
}
