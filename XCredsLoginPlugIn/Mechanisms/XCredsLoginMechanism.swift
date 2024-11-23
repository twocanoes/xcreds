import Cocoa
import CryptoTokenKit
import Network



@objc class XCredsLoginMechanism: XCredsBaseMechanism {
    var loginWebViewController: LoginWebViewController?
    @objc var signInViewController: SignInViewController?


    enum LoginWindowType {
        case cloud
        case usernamePassword
    }
    var timer:Timer?
    let checkADLog = "checkADLog"
    var loginWindowType = LoginWindowType.cloud
    var mainLoginWindowController:MainLoginWindowController?
    override init(mechanism: UnsafePointer<MechanismRecord>) {
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

      


    }
    @objc func tearDown() {
        TCSLogWithMark("Got teardown request")
        self.mainLoginWindowController?.window?.orderOut(self)
    }

    override func reload() {
        if self.loginWindowType == .cloud {
            TCSLogWithMark("reload in controller")
            mainLoginWindowController?.setupLoginWindowAppearance()
            mainLoginWindowController?.controlsViewController?.refreshGridColumn?.isHidden=false
            loginWebViewController?.loadPage()
        }
        else {
            mainLoginWindowController?.controlsViewController?.refreshGridColumn?.isHidden=true

        }
    }
    func useAutologin() -> Bool {

        if UserDefaults(suiteName: "com.apple.loginwindow")?.bool(forKey: "DisableFDEAutoLogin") ?? false {
            os_log("FDE AutoLogin Disabled per loginwindow preference key", log: checkADLog, type: .debug)
            return false
        }

        TCSLogWithMark("Checking for autologin.")
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
        if let window = mainLoginWindowController?.window {
            window.makeKeyAndOrderFront(self)
            window.orderFrontRegardless()
        }
        else {
            TCSLogWithMark("NO MAIN WINDOW FOUND")
        }

        let discoveryURL=DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue)
        let preferLocalLogin = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldPreferLocalLoginInsteadOfCloudLogin.rawValue)
        let shouldDetectNetwork = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldDetectNetworkToDetermineLoginWindow.rawValue)

        let useROPG = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseROPGForLoginWindowLogin
.rawValue)


        TCSLogWithMark("checking if local login")
        if preferLocalLogin == false,
           let _ = discoveryURL { // oidc is configured
            if shouldDetectNetwork == true,
               WifiManager().isConnectedToNetwork()==false {
                showLoginWindowType(loginWindowType: .usernamePassword)
            }
            else if useROPG == true {
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
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ XCredsLoginMechanism mech starting ~~~~~~~~~~~~~~~~~~~")

        loginWebViewController=nil
        signInViewController=nil

        if useAutologin() {
            os_log("Using autologin", log: checkADLog, type: .debug)
            super.allowLogin()
            return
        }

        if mainLoginWindowController == nil {
            mainLoginWindowController = MainLoginWindowController.init(windowNibName: "MainLoginWindowController")
        }
        mainLoginWindowController?.mechanism=self

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

        //for some reason, software update activates and gets in the way. so we delay for 3 seconds before coming back to front
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            NSApp.activate(ignoringOtherApps: true)
        }
        

        if let runDict = runDict() {

            TCSLogWithMark("Run dict = \(runDict.debugDescription)")
        }

        if let errorMessage = getContextString(type: "ErrorMessage"){
            TCSLogWithMark("Sticky error message = \(errorMessage)")

            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.messageText=errorMessage

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

        if loginWebViewController != nil || signInViewController != nil {
            TCSLogWithMark("Dismissing loginWindowWindowController")
            mainLoginWindowController?.loginTransition {
                super.allowLogin()
            }
        }
        else {
            TCSLogWithMark("calling allowLogin")
            super.allowLogin()
        }

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
            self.mainLoginWindowController?.controlsViewController?.refreshGridColumn?.isHidden=false

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

            loginWebViewController.mechanismDelegate=self



            mainLoginWindowController?.addCenterView(loginWebViewController.view)
            loginWebViewController.webView.nextKeyView=mainLoginWindowController?.controlsViewController?.view


        case .usernamePassword:
            self.mainLoginWindowController?.controlsViewController?.refreshGridColumn?.isHidden=true

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

            if let rfidUser = getHint(type: .rfidUsers) as? RFIDUsers {
                signInViewController.rfidUsers = rfidUser
                TCSLogWithMark("rfidUsers! \(rfidUser.userDict?.count ?? 0)")
            }
            else {
                TCSLogWithMark("no rfidUsers in hints")
            }

            if let localAdmin = getHint(type: .localAdmin) as? SecretKeeperUser {
                signInViewController.localAdmin = localAdmin
            }
            else {
                TCSLogWithMark("no localAdmin found in hints")
            }



            mainLoginWindowController?.addCenterView(signInViewController.view)

            TCSLogWithMark()
            mainLoginWindowController?.window?.makeFirstResponder(signInViewController.view)

            signInViewController.mechanismDelegate=self
            if signInViewController.usernameTextField != nil {
                signInViewController.usernameTextField.isEnabled=true
            }
            if signInViewController.passwordTextField != nil {
                signInViewController.passwordTextField.isEnabled=true
                signInViewController.passwordTextField.stringValue=""
            }
            if signInViewController.signIn != nil {
                signInViewController.signIn.isEnabled = true
            }
            if signInViewController.localOnlyCheckBox != nil {
                signInViewController.localOnlyCheckBox.isEnabled = true
            }
            mainLoginWindowController?.window?.forceToFrontAndFocus(self)
            mainLoginWindowController?.window?.makeFirstResponder(signInViewController.usernameTextField)

            signInViewController.signIn.nextKeyView=mainLoginWindowController?.controlsViewController?.view

        }

    }
}
