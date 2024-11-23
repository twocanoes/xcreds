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

class XCredsPowerControlMechanism: XCredsBaseMechanism {

    @objc override func run() {
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ XCredsPowerControlMechanism mech starting starting mech starting ~~~~~~~~~~~~~~~~~~~")

        if FileManager.default.fileExists(atPath: "/tmp/xcreds_return")==true{
            TCSLogWithMark("xcreds_return exists, removing")

            do{
                try FileManager.default.removeItem(atPath: "/tmp/xcreds_return")
            }
            catch {
                TCSLogWithMark("Error removing xcreds_return \(error.localizedDescription)")
            }
        }
        
        if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login"){
            TCSLogWithMark("setting standard login back to XCreds login")
            let _ = AuthorizationDBManager.shared.replace(right:"loginwindow:login", withNewRight: "XCredsLoginPlugin:LoginWindow")
        }
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
            TCSLogWithMark("Setting back to login window")
            let res = AuthorizationDBManager.shared.replace(right:"XCredsLoginPlugin:LoginWindow", withNewRight: "loginwindow:login")

            if res == false {
                TCSLogWithMark("could not restore loginwindow right")
                denyLogin(message: "Login rights could not be restored")
                return
            }
            let _ = cliTask("/usr/bin/killall 'XCreds Login Overlay'")

            let _ = cliTask("/usr/bin/killall loginwindow")

        default:
            TCSLogWithMark("No special users named. pass login to the next mech.")

            let _ = allowLogin()
        }
    }
}
