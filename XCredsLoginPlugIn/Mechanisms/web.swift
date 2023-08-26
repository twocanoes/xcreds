import Cocoa


@objc class XCredsLoginMechanism: XCredsBaseMechanism {
//    @objc var loginWindow: XCredsLoginMechanism!
    var loginWebViewWindowController: LoginWebViewWindowController?
    @objc var signInWindowController: SignInWindowController?
    var loginWindowWindowController:NSWindowController?
//    @objc var loginWindowControlsWindowController:LoginWindowControlsWindowController!

    enum LoginWindowType {
        case cloud
        case usernamePassword
    }
    let checkADLog = "checkADLog"
    var loginWindowType = LoginWindowType.cloud
    override init(mechanism: UnsafePointer<MechanismRecord>) {
        let allBundles = Bundle.allBundles
        //NSViewController(nibName: NSNib.Name("LoginWindow"), bundle: nil)
        super.init(mechanism: mechanism)
//        SwitchLoginWindow
        TCSLogWithMark("Setting up notification for switch")
        NotificationCenter.default.addObserver(forName: Notification.Name("SwitchLoginWindow"), object: nil, queue: nil) { notification in

            TCSLogWithMark("switch pressed")

            switch self.loginWindowType {

            case .cloud:
                self.showLoginWindowType(loginWindowType: .usernamePassword)
            case .usernamePassword:
                self.showLoginWindowType(loginWindowType: .cloud)
            }
        }

        for currentBundle in allBundles {
            if currentBundle.bundlePath.contains("XCreds") {
                let infoPlist = currentBundle.infoDictionary
                if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"] {
                    TCSLogInfoWithMark("------------------------------------------------------------------")
                    TCSLogInfoWithMark("XCreds Login Build Number: \(build)")
                    if DefaultsOverride.standardOverride.bool(forKey: "showDebug")==false {
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
        loginWebViewWindowController?.setupLoginWindowAppearance()

        loginWebViewWindowController?.loadPage()
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

        updateRunDict(dict: Dictionary())
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
        let discoveryURL=DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue)
        let preferLocalLogin = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldPreferLocalLoginInsteadOfCloudLogin.rawValue)

        if preferLocalLogin == false,
            let _ = discoveryURL {
            showLoginWindowType(loginWindowType: .cloud)
        }
        else {
            showLoginWindowType(loginWindowType: .usernamePassword)

        }

//        if (false){
//
//            os_log("Activating app", log: checkADLog, type: .debug)
//            NSApp.activate(ignoringOtherApps: true)
//            os_log("Loading XIB", log: checkADLog, type: .debug)
//            signIn = SignIn(windowNibName: NSNib.Name("SignIn"))
//            os_log("Set mech for loginwindow", log: checkADLog, type: .debug)
//            signIn.mech = mech
////            if let domain = self.managedDomain {
////                os_log("Set managed domain for loginwindow", log: checkADLog, type: .debug)
////                signIn.domainName = domain.uppercased()
////            }
////            if let isSSLRequired = self.isSSLRequired {
////                os_log("Set SSL required", log: checkADLog, type: .debug)
////                signIn.isSSLRequired = isSSLRequired
////            }
//            guard signIn.window != nil else {
//                os_log("Could not create login window UI", log: checkADLog, type: .default)
//                return
//            }
//            os_log("Displaying window", log: checkADLog, type: .debug)
//            if getManagedPreference(key: .NormalWindowLevel) as? Bool == false  {
//                NSApp.runModal(for: signIn.window!)
//            }
//
//            os_log("CheckAD mech complete", log: checkADLog, type: .debug)
//            return
//        }

        let isReturning = FileManager.default.fileExists(atPath: "/tmp/xcreds_return")
        TCSLogWithMark("Verifying if we should show cloud login.")

        if isReturning == false, DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowCloudLoginByDefault.rawValue) == false {
            setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.standardLoginWindow.rawValue)
            TCSLogWithMark("marking to show standard login window")

            allowLogin()
            return
        }
        TCSLogWithMark("Showing XCreds Login Window")

        NSApp.activate(ignoringOtherApps: true)

        if let runDict = runDict() {

            TCSLogWithMark("Run dict = \(runDict.debugDescription)")
        }

        if let errorMessage = getContextString(type: "ErrorMessage"){
            TCSLogWithMark("Sticky error message = \(errorMessage)")

            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.messageText=errorMessage
            if let loginWindowWindowController = loginWindowWindowController, let window = loginWindowWindowController.window{
                alert.window.level=window.level+1
            }
            alert.window.canBecomeVisibleWithoutLogin=true
            alert.icon=NSImage(named: NSImage.Name("AppIcon"))
            alert.runModal()

        }

//        loginWindowControlsWindowController = LoginWindowControlsWindowController(windowNibName: NSNib.Name("LoginWindowControls"))
//
//        guard loginWindowControlsWindowController.window != nil else {
//            TCSLogWithMark("could not create loginWindowControlsWindowController window")
//            return
//        }
//        loginWindowControlsWindowController.delegate=self
//        loginWindowControlsWindowController.window?.backgroundColor = .darkGray
//        loginWindowControlsWindowController.window?.alphaValue=0.7
    }
    override func allowLogin() {
        TCSLogWithMark("Allowing Login")
//        if loginWindowControlsWindowController != nil {
//            TCSLogWithMark("Dismissing controller")
//
//            loginWindowControlsWindowController.dismiss()
//        }

        if loginWebViewWindowController != nil {
            TCSLogWithMark("Dismissing loginWindowWindowController")
            loginWebViewWindowController?.loginTransition()
        }
        TCSLogWithMark("calling allowLogin")
        super.allowLogin()
    }
    override func denyLogin(message:String?) {
//        loginWindowControlsWindowController.close()
        loginWebViewWindowController?.loadPage()
        TCSLog("***************** DENYING LOGIN FROM LOGIN MECH ********************");
        super.denyLogin(message: message)
    }

    func showLoginWindowType(loginWindowType:LoginWindowType)  {
        TCSLogWithMark()
        switch loginWindowType {

        case .cloud:
            self.loginWindowType = LoginWindowType.cloud

            if signInWindowController != nil {
                signInWindowController?.window?.orderOut(self)
            }
//            if loginWebViewWindowController==nil{
                loginWebViewWindowController = LoginWebViewWindowController(windowNibName: "LoginWebViewController")
//            }
            
            guard let loginWebViewWindowController = loginWebViewWindowController else {
                TCSLogWithMark("could not create webViewController")
                return
            }
            guard loginWebViewWindowController.window != nil else {
                TCSLogWithMark("could not create webViewController.window")
                return
            }
            loginWebViewWindowController.delegate=self

            loginWebViewWindowController.window?.orderFrontRegardless()
            loginWebViewWindowController.window?.makeKeyAndOrderFront(self)

        case .usernamePassword:

            if loginWebViewWindowController != nil {
                loginWebViewWindowController?.window?.orderOut(self)
            }

            self.loginWindowType = .usernamePassword

            if signInWindowController==nil{
                TCSLogWithMark("Creating signInWindowController")
                signInWindowController = SignInWindowController(windowNibName: NSNib.Name("LocalUsersViewController"))
            }
            if let signInWindowController = signInWindowController {
                signInWindowController.delegate=self
                if signInWindowController.username != nil {
                    signInWindowController.username.stringValue=""
                }
                if signInWindowController.password != nil {
                    signInWindowController.password.stringValue=""
                }
                signInWindowController.window?.orderFrontRegardless()
                signInWindowController.window?.makeKeyAndOrderFront(self)
            }

        }


    }
}
