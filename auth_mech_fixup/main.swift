//
//  main.swift
//  auth_mech_fixup
//
//  Created by Timothy Perfitt on 5/31/23.
//

import Foundation

if AuthorizationDBManager.shared.rightExists(right: "XCredsLoginPlugin:LoginWindow") == true {
    TCSLogWithMark("XCreds auth rights already installed.")
    exit(0)

}
TCSLogErrorWithMark("XCreds rights do not exist. Fixing and rebooting")

if AuthRightsHelper.resetRights()==false {
    TCSLogErrorWithMark("error resetting rights")
    exit(1)
}
if AuthRightsHelper.addRights()==false {
    TCSLogErrorWithMark("error adding rights")
    exit(1)
}
