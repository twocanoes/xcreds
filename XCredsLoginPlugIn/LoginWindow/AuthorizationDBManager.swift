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

            TCSLogErrorWithMark("error getting rights to write authdb")
            return nil
        }
        return authRef!
    }
    func rightsInfo() -> Dictionary<String,Any>? {
        var rightsInfo: CFDictionary?

        let err = AuthorizationRightGet("system.login.console", &rightsInfo)

        if err != noErr {
            TCSLogErrorWithMark("error getting right")
            return nil
        }
        let rightInfo = rightsInfo as? Dictionary<String, Any>

        return rightInfo
    }
    func consoleRights() -> Array <String> {

        guard let rightInfo = rightsInfo() else {
            TCSLogErrorWithMark("error getting rightsInfo")

            return []
        }

        guard let rightsArray = rightInfo["mechanisms"] else{
            TCSLogErrorWithMark("error getting mechanisms")

            return []
        }
        guard let rightsArray = rightsArray as? Array<String> else {
            TCSLogErrorWithMark("error getting rightsArray")

            return []

        }
        return rightsArray
    }
    func setConsoleRights(rights:Array<String>) -> Bool {

        var rightInfo: CFDictionary?
        let err = AuthorizationRightGet("system.login.console", &rightInfo)

        if err != noErr {
            TCSLogErrorWithMark("error AuthorizationRightGet")

            return false
        }

        guard var rightInfo = rightInfo as? Dictionary<String, Any> else {
            TCSLogErrorWithMark("error rightInfo")

            return false
        }
        rightInfo["mechanisms"] = rights
        guard let auth = getAuth() else {
            TCSLogErrorWithMark("error getAuth")

            return false
        }
        let r = rightInfo as CFTypeRef
        let err2 = AuthorizationRightSet(auth, "system.login.console",r, nil, nil, nil)

        if err2 != noErr {
            TCSLogErrorWithMark("error AuthorizationRightSet")

            return false
        }
        return true
    }
    func replace(right:String, withNewRight newRight:String) -> Bool {

        var consoleRights = consoleRights()
        let positionOfOldRight = consoleRights.firstIndex(of: right)

        guard let positionOfOldRight = positionOfOldRight else {
            return false
        }

        consoleRights[positionOfOldRight] = newRight

        return setConsoleRights(rights: consoleRights)

    }
    func remove(right:String) -> Bool {

        var consoleRights = consoleRights()
        let positionOfOldRight = consoleRights.firstIndex(of: right)

        guard let positionOfOldRight = positionOfOldRight else {

            return false
        }

        consoleRights.remove(at: positionOfOldRight)

        return setConsoleRights(rights: consoleRights)

    }

    func rightExists(right:String)->Bool{
        let consoleRights = consoleRights()
        let positionOfRight = consoleRights.firstIndex(of: right)

        if positionOfRight == nil {
            return false
        }

        return true
    }
    func insertRight(newRight:String, afterRight right:String) -> Bool {
        var consoleRights = consoleRights()
//        TCSLogWithMark("finding right \(right)")

        let positionOfRight = consoleRights.firstIndex(of: right)

        guard let positionOfRight = positionOfRight else {
            TCSLogErrorWithMark("error positionOfRight. Not defined")

            return false
        }
        if positionOfRight+1 == consoleRights.count || consoleRights[positionOfRight+1] != newRight {

            consoleRights.insert(newRight, at: positionOfRight+1)
        }
//        else {
//            print("right already exists")
//        }


        return setConsoleRights(rights: consoleRights)
    }
    func insertRight(newRight:String, beforeRight right:String) -> Bool {
        var consoleRights = consoleRights()
        let positionOfRight = consoleRights.firstIndex(of: right)
        guard let positionOfRight = positionOfRight else {
            TCSLogWithMark("error positionOfRight. Not defined")

            return false
        }
        //makes sure it is not last and then check to see if it already exists
        if positionOfRight==0 || consoleRights[positionOfRight-1] != newRight {
            consoleRights.insert(newRight, at: positionOfRight)

        }
//        else {
//            print("right already exists")
//        }
        let success = setConsoleRights(rights: consoleRights)
        return success
    }
}
