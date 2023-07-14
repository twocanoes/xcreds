//
//  AuthRIghtsHelper.swift
//  XCreds
//
//  Created by Timothy Perfitt on 5/31/23.
//

import Foundation


class AuthRightsHelper: NSObject {
    static func resetRights() ->Bool {

        if AuthorizationDBManager.shared.rightExists(right:"XCredsLoginPlugin:LoginWindow")==true {
            TCSLogWithMark("replacing XCredsLoginPlugin:LoginWindow with loginwindow:login")
            if AuthorizationDBManager.shared.replace(right: "XCredsLoginPlugin:LoginWindow", withNewRight: "loginwindow:login") == false {
                TCSLogErrorWithMark("Error removing XCredsLoginPlugin:LoginWindow. bailing")
                return false

            }
        }
        else if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login")==false {
            TCSLogErrorWithMark("There was no XCredsLoginPlugin:LoginWindow and no loginwindow:login. Please remove /var/db/auth.db and reboot")
            return false
        }




        for authRight in AuthorizationDBManager.shared.consoleRights() {
            if authRight.hasPrefix("XCredsLoginPlugin") {
                TCSLogWithMark("Removing \(authRight)")
                if AuthorizationDBManager.shared.remove(right: authRight) == false {
                    TCSLogErrorWithMark("Error removing \(authRight)")

                }
            }

        }
        return true

    }
    static func addRights() ->Bool {

        TCSLogWithMark("Adding rights back in")
        if AuthorizationDBManager.shared.replace(right: "loginwindow:login", withNewRight: "XCredsLoginPlugin:LoginWindow")==false {
            TCSLogWithMark("error adding loginwindow:login after XCredsLoginPlugin:LoginWindow. bailing since this shouldn't happen")

            return false

        }

        for right in [["XCredsLoginPlugin:LoginWindow":"XCredsLoginPlugin:PowerControl,privileged"], ["loginwindow:done":"XCredsLoginPlugin:KeychainAdd,privileged"],["builtin:login-begin":"XCredsLoginPlugin:CreateUser,privileged"],["loginwindow:done":"XCredsLoginPlugin:EnableFDE,privileged"],["loginwindow:done":"XCredsLoginPlugin:LoginDone"]] {

            if AuthorizationDBManager.shared.rightExists(right: right.keys.first!){

                if AuthorizationDBManager.shared.insertRight(newRight: right.values.first!, afterRight: right.keys.first!) {


                    TCSLogWithMark("adding \(right.values.first!) after \(right.keys.first!)")
                }

                else {
                    TCSLogErrorWithMark("\(right.keys.first!) does not exist. not inserting \(right.values.first!)")
                }

            }
        }
        return true

    }

}
