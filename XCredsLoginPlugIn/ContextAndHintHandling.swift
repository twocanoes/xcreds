//
//  ContextAndHintHandling.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 12/18/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

enum HintType: String {
    case guestUser
    case migratePass
    case migrateUser
    case networkSignIn
    case user
    case domain
    case pass
    case first
    case last
    case full
    case groups
    case uid
    case gid
    case kerberos_principal
    case passwordOverwrite // stomp on the password
    case ntName
    case tokens

}

// attribute statics

let kODAttributeADUser = "dsAttrTypeStandard:ADUser"
let kODAttributeNetworkSignIn = "dsAttrTypeStandard:NetworkSignIn"

protocol ContextAndHintHandling {
    var mech: MechanismRecord? {get}
    func setContextString(type: String, value: String)
    func setHint(type: HintType, hint: Any)
    func getContextString(type: String) -> String?
    func getHint(type: HintType) -> Any?
}

//extension ContextAndHintHandling {
//    /// Set a NoMAD Login Authorization mechanism hint.
//    ///
//    /// - Parameters:
//    ///   - type: A value from `HintType` representing the NoMad Login value to set.
//    ///   - hint: The hint value to set. Can be `String` or `[String]`
//    }
