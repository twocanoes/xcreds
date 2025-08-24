//
//  PowerControl.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 2/9/18.
//  Copyright © 2018 NoMAD. All rights reserved.
//

import IOKit
import IOKit.pwr_mgt

enum SpecialUsers: String {
    case sleep
    case restart
    case shutdown
    case standardLoginWindow
}
@available(macOS, deprecated: 11)
class XCredsPowerControlMechanism: XCredsBaseMechanism {

    @objc override func run() {
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ XCredsPowerControlMechanism mech starting starting mech starting ~~~~~~~~~~~~~~~~~~~")

//        if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login"){
//            TCSLogWithMark("setting standard login back to XCreds login")
//            let _ = AuthorizationDBManager.shared.replace(right:"loginwindow:login", withNewRight: "XCredsLoginPlugin:LoginWindow")
//        }
        guard let userName = usernameContext else {
            TCSLogWithMark("No username was set somehow, pass the login to the next mech.")
            let _ = allowLogin()
            return

        }

        switch userName {
        case SpecialUsers.sleep.rawValue:
            TCSLogWithMark("Sleeping system.")
            let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
            IOPMSleepSystem(port)
            IOServiceClose(port)
        case SpecialUsers.shutdown.rawValue:
            TCSLogWithMark("Shutting system down system")
            let _ = cliTask("/sbin/shutdown -h now")
        case SpecialUsers.restart.rawValue:
            TCSLogWithMark("Restarting system")
            let _ = cliTask("/sbin/shutdown -r now")

        case SpecialUsers.standardLoginWindow.rawValue:
            TCSLogWithMark("mechanism right to boot back to mac login window (SpecialUsers.standardLoginWindow)")
//            if
//                AuthorizationDBManager.shared.rightExists(right: "XCredsLoginPlugin:LoginWindow")==true{
//                if AuthorizationDBManager.shared.replace(right:"XCredsLoginPlugin:LoginWindow", withNewRight: "loginwindow:login") == false {
//                    TCSLogWithMark("could not replace loginwindow:login with XCredsLoginPlugin:LoginWindow")
//                }
//            }
//            for right in ["XCredsLoginPlugin:UserSetup,privileged","XCredsLoginPlugin:PowerControl,privileged","XCredsLoginPlugin:KeychainAdd,privileged","XCredsLoginPlugin:CreateUser,privileged","XCredsLoginPlugin:EnableFDE,privileged","XCredsLoginPlugin:LoginDone"] {
//
//                if AuthorizationDBManager.shared.rightExists(right:right)==true {
//                    if AuthorizationDBManager.shared.remove(right: right)
//                        == false {
//                        TCSLogWithMark("could not remove loginwindow right \(right)")
//                    }
//                }
//
//            }
            try? StateFileHelper().createFile(.returnType)
           let _ = AuthRightsHelper.resetRights()
            if UserDefaults.standard.bool(forKey: "slowReboot")==true {
               sleep(30)
            }
            StateFileHelper().killOrReboot()


        default:
            TCSLogWithMark("No special users named. pass login to the next mech.")

            let _ = allowLogin()
        }
    }
}
