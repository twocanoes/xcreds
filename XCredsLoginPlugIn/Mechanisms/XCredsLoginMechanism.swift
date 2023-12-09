import Cocoa
import Network



@objc class XCredsLoginMechanism: XCredsBaseMechanism {
    var loginWebViewController: LoginWebViewController?
    @objc var signInViewController: SignInViewController?


    enum LoginWindowType {
        case cloud
        case usernamePassword
    }
    let checkADLog = "checkADLog"
    var loginWindowType = LoginWindowType.cloud
    var mainLoginWindowController:MainLoginWindowController
    override init(mechanism: UnsafePointer<MechanismRecord>) {

        mainLoginWindowController = MainLoginWindowController.init(windowNibName: "MainLoginWindowController")
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

        let bundle = Bundle.findBundleWithName(name: "XCreds")

        if let bundle = bundle {
            let infoPlist = bundle.infoDictionary
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
            }


        }


    }
    override func reload() {
        if self.loginWindowType == .cloud {
            TCSLogWithMark("reload in controller")
            mainLoginWindowController.setupLoginWindowAppearance()

            loginWebViewController?.loadPage()
        }
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
    func selectAndShowLoginWindow(){
        TCSLogWithMark()
        if let window = mainLoginWindowController.window {
            window.makeKeyAndOrderFront(self)
            window.orderFrontRegardless()
        }
        else {
            TCSLogWithMark("NO WINDOW")
        }
        mainLoginWindowController.controlsViewController?.delegate=self

        let discoveryURL=DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue)
        let preferLocalLogin = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldPreferLocalLoginInsteadOfCloudLogin.rawValue)
//        let preventUIPath = DefaultsOverride.standardOverride.string(forKey: PrefKeys.filePathToPreventShowingUI.rawValue)
//
//        if let preventUIPath = preventUIPath,
//           FileManager.default.fileExists(atPath: preventUIPath) {
//            TCSLogWithMark("file exists at \(preventUIPath). Skipping showing XCreds login window")
//
//            return
//        }
        let shouldDetectNetwork = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldDetectNetworkToDetermineLoginWindow.rawValue)
        TCSLogWithMark("checking if local login")
        if preferLocalLogin == false,
           let _ = discoveryURL {
            if shouldDetectNetwork == true,
               WifiManager().isConnectedToNetwork()==false {
                showLoginWindowType(loginWindowType: .usernamePassword)
            }
            else {
                TCSLogWithMark("network available, showing cloud")
                showLoginWindowType(loginWindowType: .cloud)
            }
        }
        else {
            TCSLogWithMark("preferring showing local")
            showLoginWindowType(loginWindowType: .usernamePassword)
        }
    }
    @objc override func run() {
        TCSLogWithMark("XCredsLoginMechanism mech starting")

        if useAutologin() {
            os_log("Using autologin", log: checkADLog, type: .debug)
            os_log("Check autologin complete", log: checkADLog, type: .debug)
            allowLogin()
            return
        }
        let showLoginWindowDelaySeconds = DefaultsOverride.standardOverride.integer(forKey: PrefKeys.showLoginWindowDelaySeconds.rawValue)

        if showLoginWindowDelaySeconds > 0 {
            TCSLogWithMark("Delaying showing window by \(showLoginWindowDelaySeconds) seconds")

            sleep(UInt32(showLoginWindowDelaySeconds))
        }

        selectAndShowLoginWindow()

        let isReturning = FileManager.default.fileExists(atPath: "/tmp/xcreds_return")
        TCSLogWithMark("Verifying if we should show cloud login.")

        if isReturning == false, 
            DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowCloudLoginByDefault.rawValue) == false {
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
//            if let loginWindowWindowController = loginWindowWindowController, let window = loginWindowWindowController.window{
//                alert.window.level=window.level+1
//            }
            alert.window.canBecomeVisibleWithoutLogin=true

            let bundle = Bundle.findBundleWithName(name: "XCreds")

            if let bundle = bundle {
                TCSLogWithMark("Found bundle")

                alert.icon=bundle.image(forResource: NSImage.Name("icon_128x128"))

            }
            alert.runModal()

        }

    }
    override func allowLogin() {
        TCSLogWithMark("Allowing Login")

        if loginWebViewController != nil {
            TCSLogWithMark("Dismissing loginWindowWindowController")
            mainLoginWindowController.loginTransition()
        }
        TCSLogWithMark("calling allowLogin")
        super.allowLogin()
    }
    override func denyLogin(message:String?) {
        loginWebViewController?.loadPage()
        TCSLog("***************** DENYING LOGIN FROM LOGIN MECH ********************");
        super.denyLogin(message: message)
    }

    func showLoginWindowType(loginWindowType:LoginWindowType)  {
        TCSLogWithMark()


        switch loginWindowType {


        case .cloud:
            self.loginWindowType = LoginWindowType.cloud

            if loginWebViewController==nil{
                let bundle = Bundle.findBundleWithName(name: "XCreds")
                if let bundle = bundle{

                    loginWebViewController = LoginWebViewController(nibName:  "LoginWebViewController", bundle: bundle)
                }
            }

            guard let loginWebViewController = loginWebViewController else {
                TCSLogWithMark("could not create loginWebViewController")
                return
            }

            loginWebViewController.delegate=self
            let screenRect = NSScreen.screens[0].frame

            let screenWidth = screenRect.width
            let screenHeight = screenRect.height

            var loginWindowWidth = screenWidth //start with full size
            var loginWindowHeight = screenHeight //start with full size


            //if prefs define smaller, then resize window
            TCSLogWithMark("checking for custom height and width")
            if DefaultsOverride.standardOverride.object(forKey: PrefKeys.loginWindowWidth.rawValue) != nil  {
                let val = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowWidth.rawValue))
                if val > 100 {
                    TCSLogWithMark("setting loginWindowWidth to \(val)")
                    loginWindowWidth = val
                }
            }
            if DefaultsOverride.standardOverride.object(forKey: PrefKeys.loginWindowHeight.rawValue) != nil {
                let val = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowHeight.rawValue))
                if val > 100 {
                    TCSLogWithMark("setting loginWindowHeight to \(val)")
                    loginWindowHeight = val
                }
            }
            TCSLogWithMark("setting loginWindowWidth to \(loginWindowWidth)")

            TCSLogWithMark("setting loginWindowHeight to \(loginWindowHeight)")

            loginWebViewController.view.setFrameSize(NSMakeSize(loginWindowWidth, loginWindowHeight))
            mainLoginWindowController.addCenterView(loginWebViewController.view)


        case .usernamePassword:
            NetworkMonitor.shared.stopMonitoring()
            self.loginWindowType = .usernamePassword


            if signInViewController == nil {
                let bundle = Bundle.findBundleWithName(name: "XCreds")
                if let bundle = bundle{
                    TCSLogWithMark("Creating signInViewController")
                    signInViewController = SignInViewController(nibName: "LocalUsersViewController", bundle:bundle)
                }
            }

            guard let signInViewController = signInViewController else {
                TCSLogWithMark("could not create signInViewController")
                return
            }
            TCSLogWithMark()

            mainLoginWindowController.addCenterView(signInViewController.view)
            
            TCSLogWithMark()
            mainLoginWindowController.window?.makeFirstResponder(signInViewController.view)

            signInViewController.delegate=self
            if signInViewController.usernameTextField != nil {
                signInViewController.usernameTextField.isEnabled=true
            }
            if signInViewController.passwordTextField != nil {
                signInViewController.passwordTextField.isEnabled=true
                signInViewController.passwordTextField.stringValue=""
            }


        }


    }
}
