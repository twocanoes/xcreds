//
//  SignIn.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa
import Security.AuthorizationPlugin
import os.log
import NoMAD_ADAuth
import OpenDirectory
let uiLog = OSLog(subsystem: "menu.nomad.login.ad", category: "UI")
let checkADLog = OSLog(subsystem: "menu.nomad.login.ad", category: "CheckADMech")

class SignInWindowController: NSWindowController, DSQueryable {
    
    //MARK: - setup properties
    var mech: MechanismRecord?
    var session: NoMADSession?
    var shortName = ""
    var domainName = ""
    var passString = ""
    var isDomainManaged = false
    var isSSLRequired = false
    var backgroundWindow: NSWindow!
    var effectWindow: NSWindow!
    var passChanged = false
    let wifiManager = WifiManager()
    let sysInfo = SystemInfoHelper().info()
    var sysInfoIndex = 0
    var originalPass: String?
    var delegate: XCredsMechanismProtocol?

    @objc var visible = true
    
    //MARK: - IB outlets
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var localOnlyCheckBox: NSButton!
//    @IBOutlet weak var domain: NSPopUpButton!
    @IBOutlet weak var signIn: NSButton!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var loginStack: NSStackView!
//    @IBOutlet weak var passwordChangeStack: NSStackView!
//    @IBOutlet weak var passwordChangeButton: NSButton!
//    @IBOutlet weak var oldPassword: NSSecureTextField!
//    @IBOutlet weak var newPassword: NSSecureTextField!
//    @IBOutlet weak var newPasswordConfirmation: NSSecureTextField!
//    @IBOutlet weak var alertText: NSTextField!
//    @IBOutlet weak var networkSelection: NSButton!
//    @IBOutlet weak var systemInfo: NSButton!
//    @IBOutlet weak var powerControlStack: NSStackView!
    @IBOutlet weak var loginWindowTextField: NSTextField!
    @IBOutlet weak var loginWindowTextWindow: NSWindow!
    
    //MARK: - Shutdown and Restart
    
    @IBOutlet weak var restartButton: NSButton!
    @IBOutlet weak var restartText: NSTextField!
    @IBOutlet weak var shutdownButton: NSButton!
    @IBOutlet weak var shutdownText: NSTextField!
    
    //MARK: - Migrate Box IB outlets
    var migrate = false
    @IBOutlet weak var migrateBox: NSBox!
    @IBOutlet weak var migrateText: NSTextField!
    @IBOutlet weak var migrateUsers: NSPopUpButton!
    @IBOutlet weak var migratePassword: NSSecureTextField!
    @IBOutlet weak var migrateOK: NSButton!
    @IBOutlet weak var migrateOverwrite: NSButton!
    @IBOutlet weak var migrateCancel: NSButton!
    @IBOutlet weak var MigrateNo: NSButton!
    @IBOutlet weak var migrateSpinner: NSProgressIndicator!
    @IBOutlet weak var usernameLabel: NSTextField!
    var migrateUserRecord : ODRecord?
    let localCheck = LocalCheckAndMigrate()
    var didUpdateFail = false
    var setupDone=false
    //MARK: - UI Methods


    override func awakeFromNib() {
        TCSLogWithMark()
        if setupDone == false {
            prepareAccountStrings()
            setupDone=true


            TCSLogWithMark("Configure login window")
            loginAppearance()

            TCSLogWithMark("create background windows")
            createBackground()

            TCSLogWithMark("Become first responder")
            username.becomeFirstResponder()

            os_log("Finsished loading loginwindow", log: uiLog, type: .debug)

            // Disabling due to it causing screen resizing during EULA
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self,
                                           selector: #selector(updateWindowAfterResize),
                                           name: NSApplication.didChangeScreenParametersNotification,
                                           object: nil)
        }
         
    }


    fileprivate func createBackground() {
//        var image: NSImage?
        // Is a background image path set? If not just use gray.
//        if let backgroundImage = getManagedPreference(key: .BackgroundImage) as? String  {
//            os_log("BackgroundImage preferences found.", log: uiLog, type: .debug)
//            image = NSImage(contentsOf: URL(fileURLWithPath: backgroundImage))
//        }
//
//        if let backgroundImageData = getManagedPreference(key: .BackgroundImageData) as? Data {
//            os_log("BackgroundImageData found", log: uiLog, type: .debug)
//            image = NSImage(data: backgroundImageData)
//        }
        let backgroundImage = DefaultsHelper.backgroundImage()
        let screenRect = NSScreen.screens[0].frame

        if let backgroundImage = backgroundImage {
            imageView.image?.size=screenRect.size
            imageView.image=backgroundImage

            backgroundImage.size=screenRect.size
            imageView.imageScaling = .scaleProportionallyUpOrDown

            imageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)

        }


//        for screen in NSScreen.screens {
//            let view = NSView()
//            view.wantsLayer = true
//            view.layer!.contents = image
//
//            backgroundWindow = NSWindow(contentRect: screen.frame,
//                                        styleMask: .fullSizeContentView,
//                                        backing: .buffered,
//                                        defer: true)
//
//            backgroundWindow.backgroundColor = .gray
//            backgroundWindow.contentView = view
//            backgroundWindow.makeKeyAndOrderFront(self)
//            backgroundWindow.canBecomeVisibleWithoutLogin = true
//
//            let effectView = NSVisualEffectView()
//            effectView.wantsLayer = true
//            effectView.blendingMode = .behindWindow
//            effectView.frame = screen.frame
//
//            effectWindow = NSWindow(contentRect: screen.frame,
//                                    styleMask: .fullSizeContentView,
//                                    backing: .buffered,
//                                    defer: true)
//
//            effectWindow.contentView = effectView
//
//            if let backgroundImageAlpha = getManagedPreference(key: .BackgroundImageAlpha) as? Int {
//                effectWindow.alphaValue = CGFloat(Double(backgroundImageAlpha) * 0.1)
//            } else {
//                effectWindow.alphaValue = 0.8
//            }
//
//            effectWindow.orderFrontRegardless()
//            effectWindow.canBecomeVisibleWithoutLogin = true
//        }
    }


    func loginTransition() {
        os_log("Transitioning... fade our UI away", log: uiLog, type: .debug)

        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 1.0
            context.allowsImplicitAnimation = true
//            self.window?.alphaValue = 0.0
            self.backgroundWindow.alphaValue = 0.0
            self.effectWindow.alphaValue = 0.0
        }, completionHandler: {
            os_log("Close all the windows", log: uiLog, type: .debug)
//            self.window?.close()
            self.backgroundWindow.close()
            self.effectWindow.close()
            self.visible = false
        })
    }
    
    @objc fileprivate func updateWindowAfterResize() {

        DispatchQueue.main.async{
            if self.window?.isVisible ?? true {
                os_log("Reconfiguring login window after screen change", log: uiLog, type: .debug)
                self.loginAppearance()

                os_log("Become first responder", log: uiLog, type: .debug)
                self.username.becomeFirstResponder()
            }

            //        os_log("create background windows", log: uiLog, type: .debug)
            self.createBackground()
        }
    }
    

    fileprivate func loginAppearance() {
        TCSLogWithMark()
        os_log("Setting window level", log: uiLog, type: .debug)

        self.window?.level = .normal
        self.window?.orderFrontRegardless()


        // make things look better

        os_log("Tweaking appearance", log: uiLog, type: .debug)



        if let usernamePlaceholder = UserDefaults.standard.string(forKey: PrefKeys.usernamePlaceholder.rawValue){
            TCSLogWithMark("Setting username placeholder: \(usernamePlaceholder)")
            self.username.placeholderString=usernamePlaceholder
        }

        if let passwordPlaceholder = UserDefaults.standard.string(forKey: PrefKeys.passwordPlaceholder.rawValue){
            TCSLogWithMark("Setting password placeholder")

            self.password.placeholderString=passwordPlaceholder

        }
        if UserDefaults.standard.bool(forKey: PrefKeys.shouldShowLocalOnlyCheckbox.rawValue) == false {
            self.localOnlyCheckBox.isHidden = true
        }
        else {
            //show based on if there is an AD domain or not
            self.localOnlyCheckBox.isHidden = self.domainName.isEmpty
        }

        if getManagedPreference(key: .LoginScreen) as? Bool == false {
            os_log("Present as login screen", log: uiLog, type: .debug)
            self.window?.isOpaque = false
            self.window?.hasShadow = false
            self.window?.backgroundColor = .clear
        } else {
            os_log("Present as login window", log: uiLog, type: .debug)
            self.window?.backgroundColor = NSColor.lightGray
        }
        self.window?.titlebarAppearsTransparent = true
        if !self.domainName.isEmpty {
            self.isDomainManaged = true
        }

//        if let domainList = getManagedPreference(key: .AdditionalADDomainList) as? [String] {
//            domain.isHidden = false
//            domain.removeAllItems()
//            domain.addItems(withTitles: domainList)
//        }
        let screenRect = NSScreen.screens[0].frame
        let screenWidth = screenRect.width
        let screenHeight = screenRect.height

        self.window?.setFrame(NSMakeRect(0,0 , screenWidth, screenHeight), display: true)
//        self.window?.contentView?.frame.size.width=screenWidth
//        self.window?.contentView?.frame.size.height=screenHeight
        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
        self.window?.level = .normal
        self.window?.titlebarAppearsTransparent = true


        if let logoPath = getManagedPreference(key: .LoginLogo) as? String {
            os_log("Found logoPath: %{public}@", log: uiLog, type: .debug, logoPath)
            if logoPath == "NONE" {
                imageView.image = nil
            } else {
                imageView.image = NSImage(contentsOf: URL(fileURLWithPath: logoPath))
            }
        }

        if let logoData = getManagedPreference(key: .LoginLogoData) as? Data {
            os_log("Found LoginLogoData key has a value", log: uiLog, type: .debug)
            if let image = NSImage(data: logoData) as NSImage? {
                imageView.image = image
            }
        }

        // check for Logo Alpha

        if let alpha = getManagedPreference(key: .LoginLogoAlpha) as? Int {
            os_log("Updating logo alpha value", log: uiLog, type: .debug)
            switch alpha {
            case 0 :
                imageView.alphaValue = 0.0
            case 1 :
                imageView.alphaValue = 0.1
            case 2 :
                imageView.alphaValue = 0.2
            case 3 :
                imageView.alphaValue = 0.3
            case 4 :
                imageView.alphaValue = 0.4
            case 5 :
                imageView.alphaValue = 0.5
            case 6 :
                imageView.alphaValue = 0.6
            case 7 :
                imageView.alphaValue = 0.7
            case 8 :
                imageView.alphaValue = 0.8
            case 9 :
                imageView.alphaValue = 0.9
            case 10 :
                imageView.alphaValue = 1.0
            default :
                imageView.alphaValue = 0.0
            }
        }
        TCSLogWithMark()
//        networkSelection.isHidden = !(getManagedPreference(key: .AllowNetworkSelection) as? Bool ?? false)
        // Checking if the shutdown and restart options should be hidden in the UI
//        if getManagedPreference(key: .PowerControlDisabled) as? Bool == true {
//            os_log("Disabling and hiding the power control mechanisms", log: uiLog, type: .debug)
//            powerControlStack.isHidden = true
//        }
        TCSLogWithMark()
//        if let defaultSysInfo = getManagedPreference(key: .DefaultSystemInformation) as? String {
//            switch defaultSysInfo {
//            case "SystemVersion":
//                systemInfo.title = sysInfo[0]
//            case "Serial":
//                systemInfo.title = sysInfo[1]
//            case "MAC":
//                systemInfo.title = sysInfo[2]
//            case "ComputerName":
//                systemInfo.title = sysInfo[3]
//            case "Hostname":
//                systemInfo.title = sysInfo[4]
//            case "IP":
//                systemInfo.title = sysInfo[5]
//            default:
//                break
//            }
//        }
        TCSLogWithMark()
//        loginWindowTextWindow.level = .screenSaver
//        loginWindowTextWindow.backgroundColor = .clear
//        loginWindowTextWindow.orderFrontRegardless()
//        loginWindowTextWindow.canBecomeVisibleWithoutLogin = true
        TCSLogWithMark()
//        if let loginwindowText = UserDefaults(suiteName: "com.apple.loginwindow")?.string(forKey: "LoginwindowText"){
//            os_log("LoginwindowText defined: %{public}@", log: uiLog, type: .debug, loginwindowText)
//            loginWindowTextField.stringValue = loginwindowText
//        } else{
//            os_log("No LoginwindowText defined", log: uiLog, type: .debug)
//        }
    }

    fileprivate func showResetUI() {
        TCSLogWithMark()
        os_log("Adjusting UI for change controls", log: uiLog, type: .debug)
        loginStack.isHidden = true
        signIn.isHidden = true
        TCSLogWithMark()
        signIn.isEnabled = false
//        passwordChangeStack.isHidden = false
//        passwordChangeButton.isHidden = false
//        passwordChangeButton.isEnabled = true
//        oldPassword.becomeFirstResponder()
    }

    fileprivate func authFail(_ message: String?=nil) {
        TCSLogWithMark(message ?? "")
        session = nil
        password.stringValue = ""
        password.shake(self)
//        alertText.stringValue = message ?? "Authentication Failed"
        loginStartedUI()
    }

    /// Simple toggle to change the state of the NoLo window UI between active and inactive.
    fileprivate func loginStartedUI() {
        TCSLogWithMark()
        signIn.isEnabled = !signIn.isEnabled
        signIn.isHidden = !signIn.isHidden

        username.isEnabled = !username.isEnabled
        password.isEnabled = !password.isEnabled
        localOnlyCheckBox.isEnabled = !localOnlyCheckBox.isEnabled
    }


    /// When the sign in button is clicked we check a few things.
    ///
    /// 1. Check to see if the username field is blank, bail if it is. If not, animate the UI and process the user strings.
    ///
    /// 2. Check the user shortname and see if the account already exists in DSLocal. If so, simply set the hints and pass on.
    ///
    /// 3. Create a `NoMADSession` and see if we can authenticate as the user.
    @IBAction func signInClick(_ sender: Any) {
        TCSLogWithMark("Sign In button clicked")
        if username.stringValue.isEmpty {
            username.shake(self)
            TCSLogWithMark("No username entered")
            return
        }
        TCSLogWithMark()
        loginStartedUI()
        TCSLogWithMark()
//        if getManagedPreference(key: .GuestUser) as? Bool ?? false {
//
//            os_log("Checking for guest account", log: uiLog, type: .default)
//
//            let guestUsers = getManagedPreference(key: .GuestUserAccounts) as? [String] ?? ["Guest", "guest"]
//            if guestUsers.contains(username.stringValue) {
//                os_log("Guest user engaging", log: uiLog, type: .default)
//                delegate?.setHint(type: .guestUser, hint: "true")
//                shortName = username.stringValue
//                passString = UUID.init().uuidString
//                delegate?.setHint(type: .noMADDomain, hint: "GUEST")
//                delegate?.setHint(type: .firstName, hint: getManagedPreference(key: .GuestUserFirst) as? String ?? "Guest")
//                delegate?.setHint(type: .lastName, hint: getManagedPreference(key: .GuestUserLast) as? String ?? "User")
//                delegate?.setHint(type: .fullName, hint: (getManagedPreference(key: .GuestUserFirst) as? String ?? "Guest") + (getManagedPreference(key: .GuestUserLast) as? String ?? "User"))
//                setRequiredHintsAndContext()
//                completeLogin(authResult: .allow)
//                return
//            }
//        }
        
        // clear any alerts
        
//        alertText.stringValue = ""
        TCSLogWithMark()
        prepareAccountStrings()
        TCSLogWithMark()
        if self.domainName.isEmpty==true || self.localOnlyCheckBox.state == .on{
            TCSLogWithMark("do local auth only")
            if PasswordUtils.verifyUser(name: shortName, auth: passString)  {
                setRequiredHintsAndContext()
                completeLogin(authResult: .allow)
            }
            else {
                TCSLogWithMark("password check failed")
                authFail()
            }
            return

        }
        TCSLogWithMark("network auth.")
        networkAuth()

    }
    
    fileprivate func networkAuth() {
        session = NoMADSession.init(domain: domainName, user: shortName)
        TCSLogWithMark("NoMAD Login User: \(shortName), Domain: \(domainName)")
        guard let session = session else {
            TCSLogErrorWithMark("Could not create NoMADSession from SignIn window")
            return
        }
        session.useSSL = isSSLRequired
        session.userPass = passString
        session.delegate = self
        session.recursiveGroupLookup = getManagedPreference(key: .RecursiveGroupLookup) as? Bool ?? false
        
        if let ignoreSites = getManagedPreference(key: .IgnoreSites) as? Bool {
            os_log("Ignoring AD sites", log: uiLog, type: .debug)

            session.siteIgnore = ignoreSites
        }
        
        if let ldapServers = getManagedPreference(key: .LDAPServers) as? [String] {
            TCSLogWithMark("Adding custom LDAP servers")

            session.ldapServers = ldapServers
        }
        
        TCSLogWithMark("Attempt to authenticate user")
        session.authenticate()
    }


//    @IBAction func ChangePassword(_ sender: Any) {
//        guard newPassword.stringValue == newPasswordConfirmation.stringValue else {
//            os_log("New passwords didn't match", log: uiLog, type: .error)
////            alertText.stringValue = "New passwords don't match"
//            return
//        }
//
//        // set the passChanged flag
//
//        passChanged = true
//
//        //TODO: Terrible hack to be fixed once AD Framework is refactored
//        password.stringValue = newPassword.stringValue
//
//        session?.oldPass = oldPassword.stringValue
//        session?.newPass = newPassword.stringValue
//
//        os_log("Attempting password change for %{public}@", log: uiLog, type: .debug, shortName)
//
//        // disable the fields
//
//        oldPassword.isEnabled = false
//        newPassword.isEnabled = false
//        newPasswordConfirmation.isEnabled = false
//
//        session?.changePassword()
//    }


    /// Format the user and domain from the login window depending on the mode the window is in.
    ///
    /// I.e. are we picking a domain from a list, using a managed domain, or putting it on the user name with '@'.
    fileprivate func prepareAccountStrings() {
        TCSLogWithMark("Format user and domain strings")
        TCSLogWithMark()
        var providedDomainName = ""
        
        shortName = username.stringValue
        TCSLogWithMark()
        if username.stringValue.range(of:"@") != nil {
            shortName = (username.stringValue.components(separatedBy: "@").first)!

            providedDomainName = username.stringValue.components(separatedBy: "@").last!.uppercased()
            TCSLogWithMark(providedDomainName)
        }
        TCSLogWithMark()
//        if !domain.isHidden && !username.stringValue.contains("@") && !username.stringValue.contains("\\") {
//            os_log("Using domain from picker", log: uiLog, type: .default)
//            domainName = (domain.selectedItem?.title.uppercased())!
//            return
//        }
        TCSLogWithMark()
        if username.stringValue.contains("\\") {
            os_log("User entered an NT Domain name, doing lookup", log: uiLog, type: .default)
            if let ntDomains = getManagedPreference(key: .NTtoADDomainMappings) as? [String:String],
                let ntDomain = username.stringValue.components(separatedBy: "\\").first?.uppercased(),
                let user = username.stringValue.components(separatedBy: "\\").last,
                let convertedDomain =  ntDomains[ntDomain] {
                    shortName = user
                    providedDomainName = convertedDomain
            } else {
                os_log("NT Domain mapping failed, wishing the user luck on authentication", log: uiLog, type: .default)
            }
        }
        if let prefDomainName=getManagedPreference(key: .ADDomain) as? String{

            domainName = prefDomainName
        }
        if domainName != "" && providedDomainName.lowercased() == domainName.lowercased() {
            TCSLogWithMark("ADDomain being used")
            domainName = providedDomainName.uppercased()
        }

        if providedDomainName == domainName {

        }
        else if !providedDomainName.isEmpty {
            TCSLogWithMark("Optional domain provided in text field: \(providedDomainName)")
            if getManagedPreference(key: .AdditionalADDomains) as? Bool == true {
                os_log("Optional domain name allowed by AdditionalADDomains allow-all policy", log: uiLog, type: .default)
                domainName = providedDomainName
                return
            }

            if let optionalDomains = getManagedPreference(key: .AdditionalADDomains) as? [String] {
                guard optionalDomains.contains(providedDomainName.lowercased()) else {
                    TCSLogWithMark("Optional domain name not allowed by AdditionalADDomains whitelist policy")
                    return
                }
                TCSLogWithMark("Optional domain name allowed by AdditionalADDomains whitelist policy")
                domainName = providedDomainName
                return
            }

            TCSLogWithMark("Optional domain not name allowed by AdditionalADDomains policy (false or not defined)")
        }
        
        if providedDomainName == "",
            let managedDomain = getManagedPreference(key: .ADDomain) as? String {
            TCSLogWithMark("Defaulting to managed domain as there is nothing else")
            domainName = managedDomain
        }

        TCSLogWithMark("Using domain from managed domain")
        return
    }


    //MARK: - Login Context Functions

    /// Set the authorization and context hints. These are the basics we need to passthrough to the next mechanism.
    fileprivate func setRequiredHintsAndContext() {
        TCSLogWithMark()
        TCSLogWithMark("Setting hints for user: \(shortName)")
        delegate?.setHint(type: .user, hint: shortName)
        delegate?.setHint(type: .pass, hint: passString)
        TCSLogWithMark()
        os_log("Setting context values for user: %{public}@", log: uiLog, type: .debug, shortName)
        delegate?.setContextString(type: kAuthorizationEnvironmentUsername, value: shortName)
        delegate?.setContextString(type: kAuthorizationEnvironmentPassword, value: passString)
        TCSLogWithMark()

    }


    /// Complete the NoLo process and either continue to the next Authorization Plugin or reset the NoLo window.
    ///
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        switch authResult {
        case .allow:
            TCSLogWithMark("Complete login process with allow")
            delegate?.allowLogin()
//            window?.close()

        case .deny:
            TCSLogWithMark("Complete login process with deny")
            delegate?.denyLogin()

//            window?.close()

        default:
            TCSLogWithMark("Complete login process with unknown")
//            window?.close()
        }
        TCSLogWithMark("Complete login process")
//        let error = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
//        if error != noErr {
//            TCSLogWithMark("Got error setting authentication result", log: uiLog, type: .
//        }
        NSApp.stopModal()
    }


    //MARK: - Sleep, Restart, and Shut Down Actions

    @IBAction func sleepClick(_ sender: Any) {
        os_log("Sleeping system isn't supported yet", log: uiLog, type: .error)
        //        os_log("Setting sleep user", log: uiLog, type: .debug)
        //        delegate?.setHint(type: .noMADUser, hint: SpecialUsers.noloSleep.rawValue)
        //        completeLogin(authResult: .allow)
    }

    @IBAction func restartClick(_ sender: Any) {
        os_log("Setting restart user", log: uiLog, type: .debug)
//        delegate?.setHint(type: .noMADUser, hint: SpecialUsers.noloRestart.rawValue)
        completeLogin(authResult: .allow)
    }

    @IBAction func shutdownClick(_ sender: Any) {
        os_log("Setting shutdown user", log: uiLog, type: .debug)
//        setHint(type: .noMADUser, hint: SpecialUsers.noloShutdown.rawValue)
        completeLogin(authResult: .allow)
    }
    
    //MARK: - Migration Methods
    
    fileprivate func showPasswordSync() {
        // hide other possible boxes
        TCSLogWithMark()
        self.migrateBox.isHidden = true
        self.loginStack.isHidden = true
        self.signIn.isHidden = true
        self.signIn.isEnabled = true
        self.MigrateNo.isHidden = true
        self.migrateUsers.isHidden = true
        self.usernameLabel.isHidden = true
        
        // show migration box
        self.migrateOverwrite.isHidden = false
        let overwriteRed: [NSAttributedString.Key : Any] = [.foregroundColor: NSColor.red]
        self.migrateOverwrite.attributedTitle = NSMutableAttributedString(string: self.migrateOverwrite.title, attributes: overwriteRed)
        self.migrateBox.isHidden = false
        self.migrateSpinner.isHidden = false
        
        if self.didUpdateFail == true {
            self.migrateText.stringValue = "Invalid password. Try again."
        } else {
            self.migrateText.stringValue = getManagedPreference(key: .MessagePasswordSync) as? String ?? "Active Directory password does not match local password. Please enter your previous local password to update it."
        }
    }
    
    fileprivate func showMigration() {

        //RunLoop.main.perform {
        // hide other possible boxes
        os_log("Showing migration box", log: uiLog, type: .default)

        self.loginStack.isHidden = true
        self.signIn.isHidden = true
        self.signIn.isEnabled = true

        // show migration box
        self.migrateBox.isHidden = false
        self.migrateSpinner.isHidden = false
        self.migrateUsers.addItems(withTitles: self.localCheck.migrationUsers ?? [""])
        //}
    }
    
    @IBAction func clickMigrationOK(_ sender: Any) {
        RunLoop.main.perform {
            self.migrateSpinner.isHidden = false
            self.migrateSpinner.startAnimation(nil)
        }
        
        let migrateUIPass = self.migratePassword.stringValue
        if migrateUIPass.isEmpty {
            os_log("No password was entered", log: uiLog, type: .error)
            RunLoop.main.perform {
                self.migrateSpinner.isHidden = true
                self.migrateSpinner.stopAnimation(nil)
            }
            return
        }
        
        // Take a look to see if we are syncing passwords. Until the next refactor the easiest way to tell is if the picklist is hidden.
        if self.migrateUsers.isHidden {
            do {
                os_log("Password doesn't match existing local. Try to change local pass to match.", log: uiLog, type: .default)
                let localUser = try getLocalRecord(shortName)
                try localUser.changePassword(migrateUIPass, toPassword: passString)
                didUpdateFail = false
                passChanged = false
                os_log("Password sync worked, allowing login", log: uiLog, type: .default)
                delegate?.setHint(type: .migratePass, hint: migrateUIPass)
                completeLogin(authResult: .allow)
                return
            } catch {
                os_log("Unable to sync local password to Network password. Reload and try again", log: uiLog, type: .error)
                didUpdateFail = true
                showPasswordSync()
                return
            }
        }
        guard let migrateToUser = self.migrateUsers.selectedItem?.title else {
            os_log("Could not select user to migrate from pick list.", log: uiLog, type: .error)
            return
        }
        do {
            os_log("Getting user record for %{public}@", log: uiLog, type: .default, migrateToUser)
            migrateUserRecord = try getLocalRecord(migrateToUser)
            os_log("Checking existing password for %{public}@", log: uiLog, type: .default, migrateToUser)
            if migrateUIPass != passString {
                os_log("No match. Upating local password for %{public}@", log: uiLog, type: .default, migrateToUser)
                try migrateUserRecord?.changePassword(migrateUIPass, toPassword: passString)
            } else {
                os_log("Okta and local passwords matched for %{public}@", log: uiLog, type: .default, migrateToUser)
            }
            // Mark the record to add an alias if required
            os_log("Setting hints for %{public}@", log: uiLog, type: .default, migrateToUser)
            delegate?.setHint(type: .migrateUser, hint: migrateToUser)
            delegate?.setHint(type: .migratePass, hint: migrateUIPass)
            os_log("Allowing login", log: uiLog, type: .default, migrateToUser)
            completeLogin(authResult: .allow)
        } catch {
            os_log("Migration failed with: %{public}@", log: uiLog, type: .error, error.localizedDescription)
            return
        }
        
        // if we are here, the password didn't work
        os_log("Unable to migrate user.", log: uiLog, type: .error)
        self.migrateSpinner.isHidden = true
        self.migrateSpinner.stopAnimation(nil)
        self.migratePassword.stringValue = ""
        self.completeLogin(authResult: .deny)
    }
    
    @IBAction func clickMigrationCancel(_ sender: Any) {
        passChanged = false
        didUpdateFail = false
        completeLogin(authResult: .deny)
    }
    
    @IBAction func clickMigrationNo(_ sender: Any) {
        // user doesn't want to migrate, so create a new account
        completeLogin(authResult: .allow)
    }
    
//    @IBAction func clickMigrationOverwrite(_ sender: Any) {
//        // user wants to overwrite their current password
//        os_log("Password Overwrite selected", log: uiLog, type: .default)
//        localCheck.mech = self.mech
//        delegate?.setHint(type: .passwordOverwrite, hint: true)
//        completeLogin(authResult: .allow)
//    }
    
//    @IBAction func showNetworkConnection(_ sender: Any) {
//        username.isHidden = true
//        guard let windowContentView = self.window?.contentView, let wifiView = WifiView.createFromNib(in: .mainLogin) else {
//            os_log("Error showing network selection.", log: uiLog, type: .debug)
//            return
//        }
//
//        wifiView.frame = windowContentView.frame
//        let completion = {
//            os_log("Finished working with wireless networks", log: uiLog, type: .debug)
//            self.username.isHidden = false
//            self.username.becomeFirstResponder()
//        }
//        wifiView.set(completionHandler: completion)
//        windowContentView.addSubview(wifiView)
//    }
//
//    @IBAction func clickInfo(_ sender: Any) {
//        if sysInfo.count > sysInfoIndex + 1 {
//            sysInfoIndex += 1
//        } else {
//            sysInfoIndex = 0
//        }
//
//        systemInfo.title = sysInfo[sysInfoIndex]
//        os_log("System information toggled", log: uiLog, type: .debug)
//    }
//    func verify() {
//
//            if XCredsBaseMechanism.checkForLocalUser(name: shortName) {
//                TCSLogWithMark()
//                os_log("Verify local user login for %{public}@", log: uiLog, type: .default, shortName)
//
//                if getManagedPreference(key: .DenyLocal) as? Bool ?? false {
//                    os_log("DenyLocal is enabled, looking for %{public}@ in excluded users", log: uiLog, type: .default, shortName)
//
//                    var exclude = false
//
//                    if let excludedUsers = getManagedPreference(key: .DenyLocalExcluded) as? [String] {
//                        if excludedUsers.contains(shortName) {
//                            os_log("Allowing local sign in via exclusions %{public}@", log: uiLog, type: .default, shortName)
//                            exclude = true
//                        }
//                    }
//
//                    if !exclude {
//                        os_log("No exclusions for %{public}@, denying local login. Forcing network auth", log: uiLog, type: .default, shortName)
//                        networkAuth()
//                        return
//                    }
//                }
//                TCSLogWithMark()
//                if PasswordUtils.verifyUser(name: shortName, auth: passString) {
//                    TCSLogWithMark()
//                    os_log("Allowing local user login for %{public}@", log: uiLog, type: .default, shortName)
//                    setRequiredHintsAndContext()
//                    TCSLogWithMark()
//                    completeLogin(authResult: .allow)
//                    return
//                } else {
//                    os_log("Could not verify %{public}@", log: uiLog, type: .default, shortName)
//                    authFail()
//                    return
//                }
//            }
//
//    }

}


//MARK: - NoMADUserSessionDelegate
extension SignInWindowController: NoMADUserSessionDelegate {
    
    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        TCSLogWithMark("NoMADAuthenticationFailed: \(description)")
        
//        if passChanged {
//            os_log("Password change failed.", log: uiLog, type: .default)
//            os_log("Password change failure description: %{public}@", log: uiLog, type: .error, description)
//            oldPassword.isEnabled = true
//            newPassword.isEnabled = true
//            newPasswordConfirmation.isEnabled = true
//
//            newPassword.stringValue = ""
//            newPasswordConfirmation.stringValue = ""
//
////            alertText.stringValue = "Password change failed"
//            return
//        }
        
        switch error {
        case .PasswordExpired:
            TCSLogErrorWithMark("Password is expired or requires change.")
            showResetUI()
            return
        case .OffDomain:
            TCSLogErrorWithMark("OffDomain")

            if PasswordUtils.verifyUser(name: shortName, auth: passString)  {
                setRequiredHintsAndContext()
                completeLogin(authResult: .allow)
            } else {
                authFail()
            }

            TCSLogErrorWithMark("AD authentication failed, off domain.")
//            if getManagedPreference(key: .LocalFallback) as? Bool ?? false {
//                os_log("Local fallback enabled, passing off to local authentication", log: uiLog, type: .default)
//                return
//            } else {
//                authFail();
//                return
//            }
        default:
            TCSLogErrorWithMark("NoMAD Login Authentication failed with: \(description)")
            if PasswordUtils.verifyUser(name: shortName, auth: passString)  {
                setRequiredHintsAndContext()
                completeLogin(authResult: .allow)
            } else {
                authFail()
            }
            return
        }
    }


    func NoMADAuthenticationSucceded() {
        
        if getManagedPreference(key: .RecursiveGroupLookup) as? Bool ?? false {
            session?.recursiveGroupLookup = true
        }
        
//        if passChanged {
//            // need to ensure the right password is stashed
//            passString = newPassword.stringValue
//            passChanged = false
//        }
        
        TCSLogWithMark("Authentication succeeded, requesting user info")
        session?.userInfo()
    }

//callback from ADAuth framework when userInfo returns
    func NoMADUserInformation(user: ADUserRecord) {
        
        var allowedLogin = true
        
        TCSLogWithMark("Checking for DenyLogin groups")
        
        if let allowedGroups = getManagedPreference(key: .DenyLoginUnlessGroupMember) as? [String] {
            TCSLogErrorWithMark("Found a DenyLoginUnlessGroupMember key value: \(allowedGroups.debugDescription)")
            
            // set the allowed login to false for now
            
            allowedLogin = false
            
            user.groups.forEach { group in
                if allowedGroups.contains(group) {
                    allowedLogin = true
                    TCSLogErrorWithMark("User is a member of %{public}@ group. Setting allowedLogin = true ")
                }
            }
        }
    
        if let ntName = user.customAttributes?["msDS-PrincipalName"] as? String {
            TCSLogWithMark("Found NT User Name: \(ntName)")
            delegate?.setHint(type: .ntName, hint: ntName)
        }
        
        if allowedLogin {
            
            setHints(user: user)

            // check for any migration and local auth requirements
            let localCheck = LocalCheckAndMigrate()
            localCheck.delegate = delegate
//            localCheck.mech = self.mech
            switch localCheck.run(userToCheck: user.shortName, passToCheck: passString) {

            case .fullMigration:
                showMigration()
            case .syncPassword:
                // first check to see if we can resolve this ourselves
                TCSLogWithMark("Sync password called.")

                if originalPass != nil {
                    TCSLogWithMark("Attempting to sync local pass.")
                    if localCheck.syncPass(oldPass: originalPass!) {
                        // password changed clean
                        completeLogin(authResult: .allow)
                        return
                    } else {
                        // unable to change the pass, let user fix
                        showPasswordSync()
                    }
                } else {
                    showPasswordSync()
                }
            case .errorSkipMigration, .skipMigration, .userMatchSkipMigration, .complete:
                completeLogin(authResult: .allow)
            }
        } else {
            authFail()
//            alertText.stringValue = "Not authorized to login."
            showResetUI()
        }
    }
    
    fileprivate func setHints(user: ADUserRecord) {
        TCSLogWithMark()
        os_log("NoMAD Login Looking up info for: %{public}@", log: uiLog, type: .default, user.shortName)
        setRequiredHintsAndContext()
        delegate?.setHint(type: .firstName, hint: user.firstName)
        delegate?.setHint(type: .lastName, hint: user.lastName)
        delegate?.setHint(type: .noMADDomain, hint: domainName)
        delegate?.setHint(type: .adGroups, hint: user.groups)
        delegate?.setHint(type: .fullName, hint: user.cn)
        delegate?.setHint(type: .kerberos_principal, hint: user.userPrincipal)
        delegate?.setHint(type: .ntName, hint: user.ntName)
        
        // set the network auth time to be added to the user record
        delegate?.setHint(type: .networkSignIn, hint: String(describing: Date.init().description))
    }

}


//MARK: - NSTextField Delegate
extension SignInWindowController: NSTextFieldDelegate {
    public func controlTextDidChange(_ obj: Notification) {
        let passField = obj.object as! NSTextField
        passString = passField.stringValue
    }
}


//MARK: - ContextAndHintHandling Protocol
//extension SignIn: ContextAndHintHandling {}

extension NSWindow {

    func shakeWindow(){
        let numberOfShakes      = 3
        let durationOfShake     = 0.25
        let vigourOfShake : CGFloat = 0.015

        let frame : CGRect = self.frame
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: frame.minX, y: frame.minY))

        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x: frame.minX - frame.size.width * vigourOfShake, y: frame.minY))
            shakePath.addLine(to: CGPoint(x: frame.minX + frame.size.width * vigourOfShake, y: frame.minY))
        }

        shakePath.closeSubpath()

        shakeAnimation.path = shakePath;
        shakeAnimation.duration = durationOfShake;

        self.animations = [NSAnimatablePropertyKey("frameOrigin"):shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
    }

}

