//
//  MainController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa
import OIDCLite
class MainController: NSObject, UpdateCredentialsFeedbackProtocol {

    var passwordCheckTimer:Timer?
    var feedbackDelegate:TokenManagerFeedbackDelegate?

    let scheduleManager = ScheduleManager()
    var passwordExpires:String?
    var nextPasswordCheck:String {
        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

            let dateString = dateFormatter.string(from: scheduleManager.nextCheckTime)
            return dateString

    }
    var credentialStatus:String?
    var hasCredential:Bool?
    var hasKerberosTicket:Bool?
    let windowController =  DesktopLoginWindowController(windowNibName: "DesktopLoginWindowController")
    var signInViewController:SignInViewController?


    init(passwordCheckTimer: Timer? = nil, feedbackDelegate: TokenManagerFeedbackDelegate? = nil, passwordExpires: String? = nil, nextPasswordCheck: String? = nil, credentialStatus: String? = nil, hasCredential: Bool? = nil, signInViewController: SignInViewController? = nil) {
        self.passwordCheckTimer = passwordCheckTimer
        self.feedbackDelegate = feedbackDelegate
        self.passwordExpires = passwordExpires
        self.credentialStatus = credentialStatus
        self.hasCredential = hasCredential
        self.signInViewController = signInViewController
        super.init()
        scheduleManager.feedbackDelegate=self
        let accountAndPassword = localAccountAndPassword()
        if let password = accountAndPassword.1 {
            scheduleManager.kerberosPassword = password
        }
        self.scheduleManager.startCredentialCheck()
    }

    func showSignInWindow()  {
        windowController.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)

        scheduleManager.setNextCheckTime()
        if (DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseROPGForMenuLogin.rawValue) == true || DefaultsOverride.standardOverride.value(forKey: PrefKeys.aDDomain.rawValue) != nil )
        {

            if let window = windowController.window{
                let bundle = Bundle.findBundleWithName(name: "XCreds")
                if let bundle = bundle{
                    TCSLogWithMark("Creating signInViewController")
                    if signInViewController == nil {
                        signInViewController = SignInViewController(nibName: "LocalUsersViewController", bundle:bundle)
                    }

                    signInViewController?.isInUserSpace = true
                    signInViewController?.updateCredentialsFeedbackDelegate=self
                    guard let signInViewController = signInViewController else {
                        return
                    }

                    if let contentView = window.contentView {

                        signInViewController.view.wantsLayer=true

                        if let contentView = window.contentView{
                            if contentView.subviews.contains(signInViewController.view)==false {
                                window.contentView?.addSubview(signInViewController.view)

                            }


                        }
                        signInViewController.setupLoginAppearance()

                        var x = NSMidX(contentView.frame)
                        var y = NSMidY(contentView.frame)

                        x = x - signInViewController.view.frame.size.width/2
                        y = y - signInViewController.view.frame.size.height/2
                        let lowerLeftCorner = NSPoint(x: x, y: y)
                        signInViewController.localOnlyCheckBox.isHidden = true
                        signInViewController.localOnlyView.isHidden = true

                        signInViewController.view.setFrameOrigin(lowerLeftCorner)
                    }

                    window.makeKeyAndOrderFront(self)

                }
            }
        }
        else if DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue) != nil && DefaultsOverride.standardOverride.value(forKey: PrefKeys.clientID.rawValue) != nil {

            windowController.webViewController.updateCredentialsFeedbackDelegate=self
            windowController.window!.makeKeyAndOrderFront(self)
            windowController.webViewController?.loadPage()
        }

    }

    func setup() {

        TCSLogWithMark()

        // make sure we have the local password, else prompt. we don't need to save it
        // just make sure we prompt if not in the keychain. if the user cancels, then it will
        // prompt when using OAuth.
        // don't need to save it. just need to prompt and it gets saved
        // in the keychain

//
//            scheduleManager.checkADPasswordExpire(password: password)
//            passwordCheckTimer = Timer.scheduledTimer(withTimeInterval: 3*60*60, repeats: true, block: { _ in
//                self.scheduleManager.checkADPasswordExpire(password: password)
//            })
//
//        }
        let discoveryURL = DefaultsOverride.standardOverride.string(forKey: PrefKeys.discoveryURL.rawValue)

        if discoveryURL == nil {
            return
        }

    }

    //get local password either from keychain or prompt. If prompt, then it will save in keychain for next time. if keychain, get keychain and test to make sure it is valid.
    func localAccountAndPassword() -> (String?,String?) {
        let keychainUtil = KeychainUtil()
        var accountName=""
        let accountInfo = try? keychainUtil.findPassword(serviceName: PrefKeys.password.rawValue,accountName: nil)


        if let accountInfo=accountInfo, let account=accountInfo.0, let password = accountInfo.1 {
            accountName = account

            if PasswordUtils.verifyCurrentUserPassword(password: password) == true {
                return (account,password)
            }
        }
        TCSLogWithMark()
        let promptPasswordWindowController = VerifyLocalPasswordWindowController()

        
        promptPasswordWindowController.showResetText=false
        promptPasswordWindowController.showResetButton=false

        switch  promptPasswordWindowController.promptForLocalAccountAndChangePassword(username: PasswordUtils.currentConsoleUserName, newPassword: nil, shouldUpdatePassword: false) {

        case .success(let localUsernamePassword):
            guard let localPassword = localUsernamePassword?.password else {
                return (nil,nil)

            }
            let err = keychainUtil.updatePassword(serviceName: "xcreds local password",accountName:accountName, pass:localPassword, shouldUpdateACL: true)
            if err == false {
                return (nil,nil)
            }
            return (accountName,localPassword)

        case .resetKeychainRequested(_):
            return (nil,nil)

        case .userCancelled:
            return (nil,nil)
        case .error(_):
            return (nil,nil)

        }

    }
/*
 let scheduleManager = ScheduleManager()
 var passwordExpires:String?
 var nextPasswordCheck:String?
 var credentialStatus:String?
 var hasCredential:Bool?

 */
    func passwordExpiryUpdate(_ passwordExpire: String) {

        self.passwordExpires=passwordExpire
    }
    func credentialsUpdated(_ credentials:Creds) {
        hasCredential=true
        credentialStatus="Valid Tokens"
        (NSApp.delegate as? AppDelegate)?.updateStatusMenuIcon(showDot:true)

        DispatchQueue.main.async {
            self.windowController.window?.close()

            let localAccountAndPassword = self.localAccountAndPassword()
            if credentials.password != nil, let localPassword=localAccountAndPassword.1{
                if localPassword != credentials.password{
                    var updatePassword = true
                    if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.verifyPassword.rawValue)==true {
                        let verifyOIDPassword = VerifyOIDCPasswordWindowController.init(windowNibName: NSNib.Name("VerifyOIDCPassword"))
                        NSApp.activate(ignoringOtherApps: true)

                        while true {
                            let response = NSApp.runModal(for: verifyOIDPassword.window!)
                            if response == .cancel {

                                let alert = NSAlert()
                                alert.addButton(withTitle: "Skip Updating Password")
                                alert.addButton(withTitle: "Cancel")
                                alert.messageText="Are you sure you want to skip updating the local password and keychain? Your local password and keychain will be out of sync with your cloud password. "
                                let resp = alert.runModal()
                                if resp == .alertFirstButtonReturn {
                                    NSApp.stopModal(withCode: .cancel)
                                    verifyOIDPassword.window?.close()
                                    updatePassword=false
                                    break

                                }
                            }
                            let verifyCloudPassword = verifyOIDPassword.password
                            if verifyCloudPassword == credentials.password {

                                updatePassword=true

                                verifyOIDPassword.window?.close()
                                break;
                            }
                            else {
                                verifyOIDPassword.window?.shake(self)
                            }

                        }
                    }
                    if updatePassword {
                        if let cloudPassword = credentials.password {
                            try? PasswordUtils.changeLocalUserAndKeychainPassword(localPassword, newPassword: cloudPassword)

                        }
                    }
                }
                
            }
            if TokenManager.saveTokensToKeychain(creds: credentials, setACL: true, password:credentials.password ) == false {
                TCSLogErrorWithMark("error saving tokens to keychain")
            }

            self.scheduleManager.startCredentialCheck()

        }

        //delay startup to give network time to settle.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            self.scheduleManager.startCredentialCheck()
        }

    }

    func credentialsCheckFailed() {
        TCSLogWithMark()
        hasCredential=false
        credentialStatus="Invalid Credentials"
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.updateStatusMenuIcon(showDot:false)
        showSignInWindow()
    }
    func kerberosTicketUpdated() {
        TCSLogWithMark()
        hasKerberosTicket=true
        (NSApp.delegate as? AppDelegate)?.updateStatusMenuIcon(showDot:true)

        credentialStatus="Valid kerberos tickets"
    }
    func kerberosTicketCheckFailed() {
        TCSLogWithMark()
        hasKerberosTicket=false
        (NSApp.delegate as? AppDelegate)?.updateStatusMenuIcon(showDot:false)

        credentialStatus="Kerberos Tickets Failed"
        showSignInWindow()
    }
    func adUserUpdated(_ adUser: ADUserRecord) {

        (NSApp.delegate as? AppDelegate)?.updateShareMenu(adUser: adUser)

    }

}

