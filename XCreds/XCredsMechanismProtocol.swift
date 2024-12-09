//
//  XCredsMechanismProtocol.swift
//  XCreds
//
//  Created by Timothy Perfitt on 12/24/23.
//

enum SetupHintsResult {
    case success
    case failure(String)
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

    func reload()
    func run()
    func setupHints(fromCredentials credentials:Creds, password:String) -> SetupHintsResult
}
