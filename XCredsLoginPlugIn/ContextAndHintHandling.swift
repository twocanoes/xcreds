//
//  ContextAndHintHandling.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 12/18/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

enum HintType: String,CaseIterable {
    case uid
    case gid
    case longname
    case shell
    case authorizeright = "authorize-right"
    case authorize_rule = "authorize-rule"
    case client_path = "client-path"
    case client_pid =  "client-pid"
    case client_type = "client-type"
    case client_uid = "client-uid"
    case tries
    case suggested_user = "suggested-user"
    case require_user_in_group = "require-user-in-group"
    case reason
    case token_name = "token-name"
    case afp_dir
    case kerberos_principal = "kerberos-principal"
    case mountpoint
    case new_password
    case show_add_to_keychain = "show-add-to-keychain"
    case add_to_keuychain = "add-to-keuychain"
    case Home_Dir_Mount_Result
    case homeDirType
    case noMADUser
    case noMADFirst
    case noMADLast
    case noMADFull
    case username
    case ap_pam_service_name = "ap-pam-service-name"
    case ctk
    case ap_user_name = "ap-user-name"
    case password
    case authenticated_token_id = "authenticated-token-id"
    case ap_token
    case hsh
    case uti
    case uth
    case apsso_kcp = "apsso-kcp"
    case apsso_up = "apsso-up"
    case userSecretTriesLeft
    case noMADDomain
    case tokens
    case passwordOverwrite // stomp on the password
    case ntName
    case aliasName
    case claimsToAddToLocalUserAccount
    case adUserAttributesToAddToLocalUserAccount
    case guestUser
    case existingLocalUserPassword
    case existingLocalUserName
    case networkSignIn
    case user
    case fullusername
    case domain
    case pass
    case firstName
    case lastName
    case fullName
    case groups
    case rfidUsers
    case rfidEnabled
    case localAdmin
    case rfidUid
    case localLogin
    case allADAttributes
    case rfidPIN
    case oidcLastLoginTimestamp


}

// attribute statics

let kODAttributeADUser = "dsAttrTypeStandard:ADUser"
let kODAttributeNetworkSignIn = "dsAttrTypeStandard:NetworkSignIn"

protocol ContextAndHintHandling {
    var mech: MechanismRecord? {get}
    func setContextString(type: String, value: String)
    func setHint(type: HintType, hint: NSSecureCoding)
    func getContextString(type: String) -> String?
    func getHint(type: HintType) -> Any?
}
//extension ContextAndHintHandling {
//    /// Set a NoMAD Login Authorization mechanism hint.
//    ///
//    /// - Parameters:
//    ///   - type: A value from `HintType` representing the NoMad Login value to set.
//    ///   - hint: The hint value to set. Can be `String` or `[String]`
//    func setHint(type: HintType, hint: Any) {
//        TCSLogWithMark()
//        guard (hint is String || hint is [String] || hint is Bool) else {
////            os_log("NoMAD Login Set hint failed: data type of hint is not supported", log: uiLog, type: .debug)
//            return
//        }
//        TCSLogWithMark()
//        let data = NSKeyedArchiver.archivedData(withRootObject: hint)
//        TCSLogWithMark()
//        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
//        TCSLogWithMark()
//        let err = (mech?.fPlugin.pointee.fCallbacks.pointee.SetHintValue((mech?.fEngine)!, type.rawValue, &value))!
//        TCSLogWithMark()
//        guard err == errSecSuccess else {
////            os_log("NoMAD Login Set hint failed with: %{public}@", log: uiLog, type: .debug, err)
//            return
//        }
//    }
//
//    func getHint(type: HintType) -> Any? {
//        var value : UnsafePointer<AuthorizationValue>? = nil
//        var err: OSStatus = noErr
//        err = (mech?.fPlugin.pointee.fCallbacks.pointee.GetHintValue((mech?.fEngine)!, type.rawValue, &value))!
//        if err != errSecSuccess {
////            os_log("Couldn't retrieve hint value: %{public}@", log: uiLog, type: .debug, type.rawValue)
//            return nil
//        }
//        let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
//        guard let result = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
//            else {
////                os_log("Couldn't unpack hint value: %{public}@", log: uiLog, type: .debug, type.rawValue)
//                return nil
//        }
//        return result
//    }
//
//    /// Set one of the known `AuthorizationTags` values to be used during mechanism evaluation.
//    ///
//    /// - Parameters:
//    ///   - type: A `String` constant from AuthorizationTags.h representing the value to set.
//    ///   - value: A `String` value of the context value to set.
//    func setContextString(type: String, value: String) {
//        let tempdata = value + "\0"
//        let data = tempdata.data(using: .utf8)
//        var value = AuthorizationValue(length: (data?.count)!, data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
//        let err = (mech?.fPlugin.pointee.fCallbacks.pointee.SetContextValue((mech?.fEngine)!, type, .extractable, &value))!
//        guard err == errSecSuccess else {
////            os_log("Set context value failed with: %{public}@", log: uiLog, type: .debug, err)
//            return
//        }
//    }
//
//    func getContextString(type: String) -> String? {
//        var value: UnsafePointer<AuthorizationValue>?
//        var flags = AuthorizationContextFlags()
//        let err = mech?.fPlugin.pointee.fCallbacks.pointee.GetContextValue((mech?.fEngine)!, type, &flags, &value)
//        if err != errSecSuccess {
////            os_log("Couldn't retrieve context value: %{public}@", log: uiLog, type: .debug, type)
//            return nil
//        }
//        if type == "longname" {
//            return String.init(bytesNoCopy: value!.pointee.data!, length: value!.pointee.length, encoding: .utf8, freeWhenDone: false)
//        } else {
//            let item = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
////            os_log("get context error: %{public}@", log: uiLog, type: .debug, item.description)
//        }
//
//        return nil
//    }
//}
