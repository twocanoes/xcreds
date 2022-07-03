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
}

class XCredsPowerControlMechanism: XCredsBaseMechanism {

    @objc override func run() {
        TCSLog("PowerControl mech starting")

        guard let userName = xcredsUser else {
            TCSLog("No username was set somehow, pass the login to the next mech.")
            let _ = allowLogin()
            return
        }

        switch userName {
        case SpecialUsers.sleep.rawValue:
            TCSLog("Sleeping system.")
            let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
            IOPMSleepSystem(port)
            IOServiceClose(port)
        case SpecialUsers.shutdown.rawValue:
            TCSLog("Shutting system down system")
            let _ = cliTask("/sbin/shutdown -h now")
        case SpecialUsers.restart.rawValue:
            TCSLog("Restarting system")
            let _ = cliTask("/sbin/shutdown -r now")
        default:
            TCSLog("No special users named. pass login to the next mech.")
            let _ = allowLogin()
        }
    }
}
