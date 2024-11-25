//
//  SecretKeeper.swift
//  encryptor
//
//  Created by Timothy Perfitt on 11/19/24.
//

import Foundation
import CryptoKit

@objc(RFIDUsers)
public class RFIDUsers:NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }
    public var userDict:Dictionary<Data,SecretKeeperUser>?
    public func encode(with coder: NSCoder) {

        coder.encode(userDict, forKey:"userDict")
    }

    public required init?(coder: NSCoder) {

        userDict = coder.decodeObject(forKey: "userDict") as? Dictionary<Data,SecretKeeperUser>
    }

    init(rfidUsers:[Data:SecretKeeperUser]) {
        self.userDict = rfidUsers
    }


}


public struct PasswordCryptor{
    func keyForAES(uid:Data) throws -> SymmetricKey {
        var keyBuffer = Data()


        keyBuffer.append(uid)

        if keyBuffer.count<7 {
            for _ in keyBuffer.count..<7 {
                keyBuffer.append(0x00)
            }
        }
        let serialNumber = getSerial().data(using: .utf8)

        guard let serialNumber = serialNumber else {
            TCSLogWithMark("serial number error")
            throw SecretKeeper.SecretKeeperError.aesEncryptionError

        }

        keyBuffer.append(serialNumber)


        let hashedBuffer = SHA256.hash(data: keyBuffer)

        let symmetricKey = SymmetricKey(data: hashedBuffer)

        return symmetricKey
    }
    func aesDecrypt(encryptedData:Data, uid:Data) throws -> Data{
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let clearTextData = try AES.GCM.open(sealedBox, using: keyForAES(uid:uid))

        return clearTextData

    }
    func aesEncrypt(clearTextData:Data, uid:Data) throws -> Data{



        let sealed = try AES.GCM.seal(clearTextData, using: keyForAES(uid:uid))

        guard let encryptedData = sealed.combined else {
            TCSLogWithMark("seal error")

            throw SecretKeeper.SecretKeeperError.aesEncryptionError
        }

        print(encryptedData.hexEncodedString())


        return encryptedData
    }
}

@objc(SecretKeeperUser)
public class SecretKeeperUser:NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }
    public var fullName:String?
    public var username:String
    public var password:Data
    public var uid:NSNumber

    public func encode(with coder: NSCoder) {

        coder.encode(fullName, forKey:"fullName")
        coder.encode(username,forKey:"username")
        coder.encode(password,forKey:"password")
        coder.encode(uid,forKey:"uid")
    }

    public required init?(coder: NSCoder) {

        fullName = coder.decodeObject(forKey: "fullName") as? String
        username = coder.decodeObject(forKey: "username") as? String ?? ""
        password = coder.decodeObject(forKey: "password") as? Data ?? Data()
        uid = coder.decodeObject(forKey: "uid") as? NSNumber ?? -1
    }

    init(fullName: String, username: String, password: String, uid:NSNumber, rfidUID:Data)  throws {


        self.fullName = fullName
        self.username = username
        guard let passwordData = password.data(using: .utf8) else {
            throw SecretKeeper.SecretKeeperError.otherError("error converting password")
        }
        let encryptedPassword = try PasswordCryptor().aesEncrypt(clearTextData: passwordData, uid: rfidUID)
        self.password = encryptedPassword

        self.uid = uid

    }



}
@objc(Secrets)
public class Secrets:NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        return true
    }
    public var localAdmin:SecretKeeperUser
    public var uidUsers:RFIDUsers


    init(localAdmin:SecretKeeperUser, uidUsers:RFIDUsers){

        self.localAdmin = localAdmin
        self.uidUsers = uidUsers

    }

    public func encode(with coder: NSCoder) {
        coder.encode(localAdmin, forKey: "localAdmin")
        coder.encode(uidUsers, forKey: "uidUsers")
    }

    public required init?(coder: NSCoder) {

        do{
            localAdmin = try coder.decodeObject(forKey: "localAdmin") as? SecretKeeperUser ?? SecretKeeperUser(fullName: "", username: "", password: "", uid: -1, rfidUID: Data())
            uidUsers = coder.decodeObject(of: RFIDUsers.self, forKey: "uidUsers") ?? RFIDUsers(rfidUsers: [:])
        }
        catch {
            TCSLogWithMark("error init of user object")
            return nil
        }
    }
}
public class SecretKeeper {
    public enum SecretKeeperError:Error {
        case errorFindingKey
        case privateKeyNotFound
        case errorCreatingKey(String)
        case errorRetrievingPublicKey
        case errorDecrypting
        case errorEncrypting
        case noSecretsFound
        case invalidSecretsData
        case invalidTag
        case errorWritingToSecretsFile
        case errorReadingSecretsFile
        case unknownError
        case aesEncryptionError
        case aesDecryptionError

        case otherError(String)

        func localizedDescription() -> String {
            switch self {

            case .errorFindingKey:
                return "errorFindingKey"
            case .privateKeyNotFound:
                return "privateKeyNotFound"

            case .errorCreatingKey(let error):
                return "errorCreatingKey: \(error)"

            case .errorRetrievingPublicKey:
                return "errorRetrievingPublicKey"

            case .errorDecrypting:
                return "errorDecrypting"

            case .errorEncrypting:
                return "errorEncrypting"

            case .noSecretsFound:
                return "noSecretsFound"

            case .invalidSecretsData:
                return "invalidSecretsData"

            case .invalidTag:
                return "invalidTag"

            case .errorWritingToSecretsFile:
                return "errorWritingToSecretsFile"

            case .errorReadingSecretsFile:
                return "errorReadingSecretsFile"

            case .unknownError:
                return "unknownError"

            case .otherError(let error):
                return error

            case .aesEncryptionError:
                return "aesEncryptionError"

            case .aesDecryptionError:
                return "aesDecryptionError"

            }


        }
    }

    private var label = ""
    private var tag = Data()
    private var secretsFolderURL:URL
    private var secretsFileURL:URL
    public init(label: String = "SecretKeeper", tag: String = "SecretKeeper", secretsFolderURL: URL = URL(fileURLWithPath: "/usr/local/var/twocanoes")) throws {
        self.label = label
        self.secretsFolderURL = secretsFolderURL
        self.secretsFileURL = secretsFolderURL.appending(path: "secrets.bin")

        if let tagData = tag.data(using: .utf8) {
            self.tag = tagData
        }
        else {
            throw SecretKeeperError.invalidTag
        }
    }


    func findExistingPrivateKey() throws -> SecKey? {

        let keychain = try systemKeychain()

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecUseKeychain as String:keychain as Any,

            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrApplicationTag as String: tag,
            kSecPrivateKeyAttrs as String:
               [kSecAttrLabel : label as CFString,
                kSecAttrIsPermanent as String:    true,
                kSecAttrApplicationTag as String: tag],

            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?

        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)

    }
    func systemKeychain()  throws -> SecKeychain{
        var keychain:SecKeychain?
        if SecKeychainCopyDomainDefault(SecPreferencesDomain.system, &keychain) != errSecSuccess {
            throw SecretKeeperError.errorFindingKey
        }

        if let keychain = keychain {
            return keychain
        }
        throw SecretKeeperError.unknownError


    }

    func privateKey() throws -> SecKey {

        if let privateKey = try findExistingPrivateKey() {
            return privateKey
        }

       let keychain = try systemKeychain()


        var secApps = [ SecTrustedApplication ]()

        var trust : SecTrustedApplication? = nil
        if FileManager.default.fileExists(atPath: "/Applications/XCreds.app", isDirectory: nil) {
            let err = SecTrustedApplicationCreateFromPath("/Applications/XCreds.app", &trust)
            if err == 0 {
                secApps.append(trust!)
            }
        }
        if FileManager.default.fileExists(atPath: "/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.x86_64.xpc", isDirectory: nil) {
            let err = SecTrustedApplicationCreateFromPath("/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.x86_64.xpc", &trust)
            if err == 0 {
                secApps.append(trust!)
            }
        }
        if FileManager.default.fileExists(atPath: "/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.arm64.xpc", isDirectory: nil) {
            let err = SecTrustedApplicationCreateFromPath("/System/Library/Frameworks/Security.framework/Versions/A/MachServices/authorizationhost.bundle/Contents/XPCServices/authorizationhosthelper.arm64.xpc", &trust)
            if err == 0 {
                secApps.append(trust!)
            }
        }

        var secAccess:SecAccess?
        let s = SecAccessCreate("XCreds Encryptor" as CFString, secApps as CFArray, &secAccess)
        let attributes: [String: Any] =
        [kSecAttrKeyType as String:
            kSecAttrKeyTypeECSECPrimeRandom,
         kSecUseKeychain as String:keychain as Any,
         kSecAttrKeySizeInBits as String:      256,
         kSecAttrIsExtractable as String:false,
         kSecAttrAccess as String: secAccess ?? "",
         kSecPrivateKeyAttrs as String:
            [kSecAttrLabel : label as CFString,
             kSecAttrIsPermanent as String:    true,
             kSecAttrApplicationTag as String: tag],
        ]
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            var errorString = ""
            if let err = error?.takeUnretainedValue().localizedDescription{
                errorString = err
            }
            throw SecretKeeperError.errorCreatingKey(errorString)

        }
        guard let privateKey = try findExistingPrivateKey() else {
            throw SecretKeeperError.privateKeyNotFound
        }
        return privateKey
    }

    func publicKey() throws -> SecKey{

        let privateKey = try privateKey()
        let publicKey = SecKeyCopyPublicKey(privateKey)

        if let publicKey = publicKey {
            return publicKey
        }
        throw SecretKeeperError.errorRetrievingPublicKey
    }
    func decryptData(_ data:Data) throws -> Data {
        var error: Unmanaged<CFError>?

        let privateKey = try privateKey()
        let decryptedData = SecKeyCreateDecryptedData(privateKey, SecKeyAlgorithm.eciesEncryptionStandardX963SHA1AESGCM, data as CFData, &error)

        if let decryptedData = decryptedData {

            return decryptedData as Data
        }
        throw SecretKeeperError.errorDecrypting


    }
    func encryptData(_ data:Data) throws -> Data {

        let publicKey = try publicKey()
        var error: Unmanaged<CFError>?

        let encryptedData = SecKeyCreateEncryptedData(publicKey,SecKeyAlgorithm.eciesEncryptionStandardX963SHA1AESGCM,data as CFData, &error)


        if let encryptedData = encryptedData {
            return encryptedData as Data
        }
        throw SecretKeeperError.errorEncrypting


    }



}

extension SecretKeeper {
    func addSecrets(_ secrets:Secrets) throws {


        let data = try NSKeyedArchiver.archivedData(withRootObject:secrets,requiringSecureCoding: true)

        let encrypted = try encryptData(data)
        var attributes = [FileAttributeKey : Any]()
        attributes[.posixPermissions] = 0o600
        attributes[.ownerAccountID] = 0
        attributes[.groupOwnerAccountID] = 0

        try FileManager.default.createDirectory(at: secretsFolderURL, withIntermediateDirectories: true, attributes:attributes)
        try encrypted.write(to:secretsFileURL )
        try FileManager.default.setAttributes(attributes, ofItemAtPath: secretsFolderURL.path() )

    }
    func secrets() throws -> Secrets {

        if FileManager.default.fileExists(atPath: secretsFileURL.path()) == false {
            return try Secrets(localAdmin: SecretKeeperUser(fullName: "", username: "", password: "", uid: 0, rfidUID: Data()), uidUsers:RFIDUsers(rfidUsers: [:]))
        }
        
        let secretData = try Data(contentsOf: secretsFileURL)

        let decryptedData = try decryptData(secretData)


        guard let secrets = NSKeyedUnarchiver.unarchiveObject(with: decryptedData) as? Secrets else {
            TCSLog("Error unarchiving")
            throw SecretKeeperError.otherError("Error unarchiving")
        }



        return secrets
        }


}
