import Cocoa


@objc class XCredsLoginMechanism: XCredsBaseMechanism {
    @objc var loginWindow: XCredsLoginMechanism!
    @objc var webViewController: LoginWebViewController!
    @objc var loginWindowControlsWindowController:LoginWindowControlsWindowController!
    let checkADLog = "checkADLog"

    override init(mechanism: UnsafePointer<MechanismRecord>) {
        super.init(mechanism: mechanism)
        let allBundles = Bundle.allBundles



        for currentBundle in allBundles {
            if currentBundle.bundlePath.contains("XCreds") {
                let infoPlist = currentBundle.infoDictionary
                if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"] {
                    TCSLogInfoWithMark("------------------------------------------------------------------")
                    TCSLogInfoWithMark("XCreds Login Build Number: \(build)")
                    if UserDefaults.standard.bool(forKey: "showDebug")==false {
                        TCSLogInfoWithMark("Log showing only basic info and errors.")
                        TCSLogInfoWithMark("Set debugLogging to true to show verbose logging with")
                        TCSLogInfoWithMark("sudo defaults write /Library/Preferences/com.twocanoes.xcreds showDebug -bool true")
                    }
                    else {
                        TCSLogInfoWithMark("To disable verbose logging:")
                        TCSLogInfoWithMark("sudo defaults delete /Library/Preferences/com.twocanoes.xcreds showDebug")

                    }

                    TCSLogInfoWithMark("------------------------------------------------------------------")
                    break
                }

            }
        }


    }
    override func reload() {
        TCSLogWithMark("reload in controller")
        webViewController.loadPage()
    }
    func useAutologin() -> Bool {

        if UserDefaults(suiteName: "com.apple.loginwindow")?.bool(forKey: "DisableFDEAutoLogin") ?? false {
            os_log("FDE AutoLogin Disabled per loginwindow preference key", log: checkADLog, type: .debug)
            return false
        }

        os_log("Checking for autologin.", log: checkADLog, type: .default)
        if FileManager.default.fileExists(atPath: "/tmp/xcredsrun") {
            os_log("XCreds has run once already. Load regular window as this isn't a reboot", log: checkADLog, type: .debug)
            return false
        }

        os_log("XCreds, trying autologin", log: checkADLog, type: .debug)
        try? "Run Once".write(to: URL.init(fileURLWithPath: "/tmp/xcredsrun"), atomically: true, encoding: String.Encoding.utf8)

        if let username = getContextString(type: "fvusername") {
            TCSLogWithMark("got username = \(username)")
        }
        else {
            TCSLogWithMark("no username found")

        }
       if let password = getContextString(type: "fvpassword") {
           TCSLogWithMark("got password ")
       }
        else {
            TCSLogWithMark("no password found")
        }

        if let username = getContextString(type: "fvusername"), let password = getContextString(type: "fvpassword") {
            os_log("Found username in context, doing autologin", log: checkADLog, type: .debug)
            setContextString(type: kAuthorizationEnvironmentUsername, value: username)
            setContextString(type: kAuthorizationEnvironmentPassword, value: password)
            return true
        } else {
            if let uuid = getEFIUUID() {
                if let name = XCredsBaseMechanism.getShortname(uuid: uuid) {
                    os_log("Found username in EFI, doing autologin", log: checkADLog, type: .debug)

                    setContextString(type: kAuthorizationEnvironmentUsername, value: name)
                    return true
                }
            }
        }
        return true
    }
    fileprivate func getEFIUUID() -> String? {
        TCSLogWithMark("getEFIUUID")
        let chosen = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen")
        var properties : Unmanaged<CFMutableDictionary>?
        let err = IORegistryEntryCreateCFProperties(chosen, &properties, kCFAllocatorDefault, IOOptionBits.init(bitPattern: 0))

        if err != 0 {
            TCSLogWithMark("getEFIUUID error")
            return nil
        }

        guard let props = properties!.takeRetainedValue() as? [ String : AnyHashable ] else {
            TCSLogWithMark("getEFIUUID error props")
            return nil

        }
        guard let uuid = props["efilogin-unlock-ident"] as? Data else {

            TCSLogWithMark("getEFIUUID error uuid")

            return nil

        }
        TCSLogWithMark("uuid=\(uuid.hexEncodedString())")

        return String.init(data: uuid, encoding: String.Encoding.utf8)
    }
    @objc override func run() {
        TCSLogWithMark("XCredsLoginMechanism mech starting")
        if useAutologin() {
            os_log("Using autologin", log: checkADLog, type: .debug)
            os_log("Check autologin complete", log: checkADLog, type: .debug)
            allowLogin()
            return
        }
        let isReturning = FileManager.default.fileExists(atPath: "/tmp/xcreds_return")
        TCSLogWithMark("Verifying if we should show cloud login.")

        if isReturning == false, UserDefaults.standard.bool(forKey: PrefKeys.shouldShowCloudLoginByDefault.rawValue) == false {
            setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.standardLoginWindow.rawValue)
            TCSLogWithMark("marking to show standard login window")

            allowLogin()
            return
        }
        TCSLogWithMark("Showing XCreds Login Window")

        NSApp.activate(ignoringOtherApps: true)

        webViewController = LoginWebViewController(windowNibName: NSNib.Name("LoginWebView"))

        guard webViewController.window != nil else {
            TCSLogWithMark("could not create xcreds window")
            return
        }
        webViewController.delegate=self

        loginWindowControlsWindowController = LoginWindowControlsWindowController(windowNibName: NSNib.Name("LoginWindowControls"))

        guard loginWindowControlsWindowController.window != nil else {
            TCSLogWithMark("could not create loginWindowControlsWindowController window")
            return
        }
        loginWindowControlsWindowController.delegate=self
        loginWindowControlsWindowController.window?.backgroundColor = .darkGray
        loginWindowControlsWindowController.window?.alphaValue=0.7
    }
    override func allowLogin() {
        TCSLogWithMark("Allowing Login")
        if loginWindowControlsWindowController != nil {
            TCSLogWithMark("Dismissing controller")

            loginWindowControlsWindowController.dismiss()
        }
        TCSLogWithMark("calling super allowLogin")
        super.allowLogin()
    }
    override func denyLogin() {
        loginWindowControlsWindowController.close()
        TCSLog("***************** DENYING LOGIN ********************");
        super.denyLogin()
    }
}
