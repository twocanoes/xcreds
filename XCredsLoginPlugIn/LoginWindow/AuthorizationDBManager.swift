//
//  AuthorizationDBManager.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/3/22.
//

import Foundation
import Security.AuthorizationDB

class AuthorizationDBManager: NSObject {
    static let shared = AuthorizationDBManager()
    private func getAuth() -> AuthorizationRef? {
        if NSUserName() != "root" {
            print("Not Running as root, please execute with sudo privilege to do this function")
            exit(1)
        }
        var authRef : AuthorizationRef? = nil
        let err = AuthorizationCreate(nil, nil, AuthorizationFlags(rawValue: 0), &authRef)

        if err != noErr {

            TCSLog("error getting rights to write authdb")
            return nil
        }
        return authRef!
    }
    func rightsInfo() -> Dictionary<String,Any>? {
        var rightsInfo: CFDictionary?

        let err = AuthorizationRightGet("system.login.console", &rightsInfo)

        if err != noErr {
            TCSLog("eror getting right")
            return nil
        }
        let rightInfo = rightsInfo as? Dictionary<String, Any>

        return rightInfo
    }
    func consoleRights() -> Array <String> {

        guard let rightInfo = rightsInfo() else {
            TCSLog("error getting rightsInfo")

            return []
        }

        guard let rightsArray = rightInfo["mechanisms"] else{
            TCSLog("error getting mechanisms")

            return []
        }
        guard let rightsArray = rightsArray as? Array<String> else {
            TCSLog("error getting rightsArray")

            return []

        }
        return rightsArray
    }
    func setConsoleRights(rights:Array<String>) -> Bool {

        var rightInfo: CFDictionary?

        let err = AuthorizationRightGet("system.login.console", &rightInfo)

        if err != noErr {
            TCSLog("error AuthorizationRightGet")

            return false
        }

        guard var rightInfo = rightInfo as? Dictionary<String, Any> else {
            TCSLog("error rightInfo")

            return false
        }
        rightInfo["mechanisms"] = rights
        guard let auth = getAuth() else {
            TCSLog("error getAuth")

            return false
        }
        let r = rightInfo as CFTypeRef
        let err2 = AuthorizationRightSet(auth, "system.login.console",r, nil, nil, nil)

        if err2 != noErr {
            TCSLog("error AuthorizationRightSet")

            return false
        }
        return true
    }
    func replace(right:String, withNewRight newRight:String) -> Bool {

    var consoleRights = consoleRights()
        let positionOfOldRight = consoleRights.firstIndex(of: right)

        guard let positionOfOldRight = positionOfOldRight else {
            TCSLog("error positionOfOldRight")

            return false
        }

        consoleRights[positionOfOldRight] = newRight

        return setConsoleRights(rights: consoleRights)

    }
    func rightExists(right:String)->Bool{
        let consoleRights = consoleRights()
        let positionOfRight = consoleRights.firstIndex(of: right)

        if positionOfRight == nil {
            TCSLog("did not find \(right)")
            return false
        }
        TCSLog("found \(right)")

        return true
    }
    func insertRight(newRight:String, afterRight right:String) -> Bool {
        var consoleRights = consoleRights()
        let positionOfRight = consoleRights.firstIndex(of: right)

        guard let positionOfRight = positionOfRight else {
            TCSLog("error positionOfRight")

            return false
        }
        consoleRights.insert(newRight, at: positionOfRight+1)

        return true
    }
    func insertRight(newRight:String, beforeRight right:String) -> Bool {
        var consoleRights = consoleRights()
        let positionOfRight = consoleRights.firstIndex(of: right)

        guard let positionOfRight = positionOfRight else {
            TCSLog("error positionOfRight2")

            return false
        }
        consoleRights.insert(newRight, at: positionOfRight)

        let success = setConsoleRights(rights: consoleRights)
        return success
    }
}
