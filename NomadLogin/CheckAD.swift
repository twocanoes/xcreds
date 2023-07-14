//
//  CheckAD.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa
import os.log

class CheckAD: NoLoMechanism {
    @objc var signIn: SignIn!
    
    @objc func run() {
        os_log("CheckAD mech starting", log: checkADLog, type: .debug)

        if useAutologin() {
            os_log("Using autologin", log: checkADLog, type: .debug)
            os_log("CheckAD mech complete", log: checkADLog, type: .debug)
            allowLogin()
            return
        }
        os_log("Activating app", log: checkADLog, type: .debug)
        NSApp.activate(ignoringOtherApps: true)
        os_log("Loading XIB", log: checkADLog, type: .debug)
        signIn = SignIn(windowNibName: NSNib.Name("SignIn"))
        os_log("Set mech for loginwindow", log: checkADLog, type: .debug)
        signIn.mech = mech
        if let domain = self.managedDomain {
            os_log("Set managed domain for loginwindow", log: checkADLog, type: .debug)
            signIn.domainName = domain.uppercased()
        }
        if let isSSLRequired = self.isSSLRequired {
            os_log("Set SSL required", log: checkADLog, type: .debug)
            signIn.isSSLRequired = isSSLRequired
        }
        guard signIn.window != nil else {
            os_log("Could not create login window UI", log: checkADLog, type: .default)
            return
        }
        os_log("Displaying window", log: checkADLog, type: .debug)
        if getManagedPreference(key: .NormalWindowLevel) as? Bool == false  {
            NSApp.runModal(for: signIn.window!)
        }
        
        os_log("CheckAD mech complete", log: checkADLog, type: .debug)
    }

    @objc func tearDown() {
        os_log("Got teardown request", log: checkADLog, type: .debug)
        signIn.loginTransition()
    }

    func useAutologin() -> Bool {
        
        if UserDefaults(suiteName: "com.apple.loginwindow")?.bool(forKey: "DisableFDEAutoLogin") ?? false {
            os_log("FDE AutoLogin Disabled per loginwindow preference key", log: checkADLog, type: .debug)
            return false
        }
        
        os_log("Checking for autologin.", log: checkADLog, type: .default)
        if FileManager.default.fileExists(atPath: "/tmp/nolorun") {
            os_log("NoLo has run once already. Load regular window as this isn't a reboot", log: checkADLog, type: .debug)
            return false
        }

        os_log("NoLo hasn't run, trying autologin", log: checkADLog, type: .debug)
        try? "Run Once".write(to: URL.init(fileURLWithPath: "/tmp/nolorun"), atomically: true, encoding: String.Encoding.utf8)

        if let uuid = getEFIUUID() {
            if let name = NoLoMechanism.getShortname(uuid: uuid) {
                setContextString(type: kAuthorizationEnvironmentUsername, value: name)
            }
        }
        return true
    }
    
    fileprivate func getEFIUUID() -> String? {
        let chosen = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen")
        var properties : Unmanaged<CFMutableDictionary>?
        let err = IORegistryEntryCreateCFProperties(chosen, &properties, kCFAllocatorDefault, IOOptionBits.init(bitPattern: 0))

        if err != 0 {
            return nil
        }

        guard let props = properties!.takeRetainedValue() as? [ String : AnyHashable ] else { return nil }
        guard let uuid = props["efilogin-unlock-ident"] as? Data else { return nil }
        return String.init(data: uuid, encoding: String.Encoding.utf8)
    }
}
