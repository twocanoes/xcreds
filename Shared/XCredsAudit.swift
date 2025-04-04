//
//  Audit.swift
//  XCreds
//
//  Created by Timothy Perfitt on 1/20/25.
//

import Foundation


class XCredsAudit {


    struct AuditRecord:Codable {
        var lastSuccessfulLoginDate:Date?
        var lastSuccessfulLoginUser:String?
        var username:String?
        var identityToken:String?
        var identityTokenUpdateDate:Date?

        var refreshTokenUpdateDate:Date?
        var refreshTokenUpdateSuccess:Bool?
        var tokenLastUpdatedDate:Date?
        var lastError:String?
        var lastErrorDate:Date?
    }
    var configFileURL:URL

    init() {
        let applicationSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .localDomainMask, true)

        let loginWindowConfigFilePath = ((applicationSupportPath[0] as NSString).appendingPathComponent("XCreds") as NSString).appendingPathComponent("xcredsaudit")

        if geteuid()==0 {
            configFileURL = URL(fileURLWithPath: loginWindowConfigFilePath)
        }

        else {
            let home = NSHomeDirectory()
            let userConfigFilePath = home + "/" + ".xcredsaudit"
            configFileURL = URL(fileURLWithPath: userConfigFilePath)
        }
    }
    internal func saveAuditRecord(_ auditRecord:AuditRecord){
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
          let data = try encoder.encode(auditRecord)
            try data.write(to: configFileURL)
        } catch {
            TCSLogWithMark(error.localizedDescription)
        }

    }
    func tokensUpdated(idToken:String)  {
        var auditRecord = AuditRecord()
        var decodedIdToken:String=idToken
        if let decodedTokenString = try? String(data: TokenManager().idTokenData(jwtString: idToken), encoding: .utf8) {
            decodedIdToken = decodedTokenString
        }

        auditRecord.identityToken = decodedIdToken
        auditRecord.identityTokenUpdateDate = Date()
        saveAuditRecord(auditRecord)

    }
    func refreshTokenUpdated(_ wasSuccessful:Bool)  {
        var auditRecord = currentAuditRecord()
        auditRecord.refreshTokenUpdateSuccess = wasSuccessful
        auditRecord.refreshTokenUpdateDate = Date()
        saveAuditRecord(auditRecord)
    }


   internal func auditError(_ error:String)  {
        var auditRecord = currentAuditRecord()
        auditRecord.lastError = error
        saveAuditRecord(auditRecord)
    }
    internal func loginWindowLogin(user:String){
        var loginWindowAuditRecord = currentAuditRecord()
        loginWindowAuditRecord.lastSuccessfulLoginUser = user
        loginWindowAuditRecord.lastSuccessfulLoginDate = Date()
        saveAuditRecord(loginWindowAuditRecord)
    }

    internal func currentAuditRecord() -> AuditRecord {
        if FileManager.default.fileExists(atPath:configFileURL.path){
            if let data = try? Data(contentsOf: configFileURL) {
              let decoder = PropertyListDecoder()
                if let auditRecord =  try? decoder.decode(AuditRecord.self, from: data) {
                    return auditRecord
                }
            }
        }
        return AuditRecord()
    }
    func auditRecord(path:String) -> AuditRecord? {
        if FileManager.default.fileExists(atPath:path){
            if let data = try? Data(contentsOf: URL(filePath:path)) {
              let decoder = PropertyListDecoder()
                if let auditRecord =  try? decoder.decode(AuditRecord.self, from: data) {
                    return auditRecord
                }
            }
        }
        return AuditRecord()
    }
    func auditRecordDictionary(_ auditRecord:AuditRecord) -> [String:String]{

        var returnDict:[String:String] = [:]

        if let lastSuccessfulLoginDate = auditRecord.lastSuccessfulLoginDate {
            returnDict["lastSuccessfulLoginDate"] = lastSuccessfulLoginDate.description
        }

        if let lastSuccessfulLoginUser = auditRecord.lastSuccessfulLoginUser {
            returnDict["lastSuccessfulLoginUser"] = lastSuccessfulLoginUser
        }

        if let username = auditRecord.username {
            returnDict["username"] = username
        }

        if let identityToken = auditRecord.identityToken {
            returnDict["identityToken"] = identityToken
        }

        if let identityTokenUpdateDate = auditRecord.identityTokenUpdateDate {
            returnDict["identityTokenUpdateDate"] = identityTokenUpdateDate.description
        }

        if let refreshTokenUpdateDate = auditRecord.refreshTokenUpdateDate {
            returnDict["refreshTokenUpdateDate"] = refreshTokenUpdateDate.description
        }

        if let refreshTokenUpdateSuccess = auditRecord.refreshTokenUpdateSuccess {
            returnDict["refreshTokenUpdateSuccess"] = refreshTokenUpdateSuccess==true ? "true":"false"
        }

        if let tokenLastUpdatedDate = auditRecord.tokenLastUpdatedDate {
            returnDict["tokenLastUpdatedDate"] = tokenLastUpdatedDate.description
        }

        if let lastError = auditRecord.lastError {
            returnDict["lastError"] = lastError
        }

        if let lastErrorDate = auditRecord.lastErrorDate {
            returnDict["lastErrorDate"] = lastErrorDate.description
        }



        return returnDict

    }
}

