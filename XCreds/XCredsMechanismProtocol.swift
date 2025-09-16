//
//  XCredsMechanismProtocol.swift
//  XCreds
//
//  Created by Timothy Perfitt on 12/24/23.
//

enum ErrorResult {
    case success
    case failure(String)
    case userCancelled
}

protocol XCredsMechanismProtocol {
    func allowLogin()
    func denyLogin(message:String?)
    func setHints(_ hints:[HintType:Any])
    func setContextStrings(_ contentStrings: [String : String])
    func setContextString(type: String, value: String)
    func setStickyContextString(type: String, value: String)
    func setHint(type: HintType, hint: NSSecureCoding)
    func setHintData(type: HintType, data: Data)

    func getHint(type: HintType) -> Any?

    func reload()
    func run()
    func setupHints(fromCredentials credentials:Creds, password:String) -> ErrorResult
    func unsyncedPasswordPrompt(username: String, password: String,accountLocked:Bool, localAdmin: LocalAdminCredentials?, showResetButton:Bool) ->ErrorResult 
}
