//
//  MainController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa
import OIDCLite
class MainController: NSObject, UpdateCredentialsFeedbackProtocol {

    

    enum LoginWindowType {
        case cloud
        case usernamePassword
    }

    var passwordCheckTimer:Timer?
    var feedbackDelegate:TokenManagerFeedbackDelegate?

    let scheduleManager = ScheduleManager()
    var adPasswordExpires:String?
    var cloudPasswordExpires:String?
    var nextPasswordCheck:String {
        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        //TODO Setup for AD as well
        let dateString = dateFormatter.string(from: scheduleManager.nextTokenCheckTime)
        return dateString

    }
    var credentialStatus:String?
    var hasCredential:Bool?
    var hasKerberosTicket:Bool?
    let windowController =  DesktopLoginWindowController(windowNibName: "DesktopLoginWindowController")
    var signInViewController:SignInViewController?


    init(passwordCheckTimer: Timer? = nil, feedbackDelegate: TokenManagerFeedbackDelegate? = nil, cloudPasswordExpires: String? = nil, adPasswordExpires: String? = nil,nextPasswordCheck: String? = nil, credentialStatus: String? = nil, hasCredential: Bool? = nil, signInViewController: SignInViewController? = nil) {
        self.passwordCheckTimer = passwordCheckTimer
        self.feedbackDelegate = feedbackDelegate
        self.adPasswordExpires = adPasswordExpires
        self.cloudPasswordExpires = cloudPasswordExpires

        self.credentialStatus = credentialStatus
        self.hasCredential = hasCredential
        self.signInViewController = signInViewController
        super.init()
        scheduleManager.feedbackDelegate=self

        let shouldShowMenuBarSignInWithoutLoginWindowSignin = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowMenuBarSignInWithoutLoginWindowSignin.rawValue)

        if isLocalOnlyAccount() == false || shouldShowMenuBarSignInWithoutLoginWindowSignin==true {
            let accountAndPassword = localAccountAndPassword()
            if let password = accountAndPassword.1 {
                scheduleManager.kerberosPassword = password
            }
            self.scheduleManager.startCredentialCheck()
        }


    }



    func isLocalOnlyAccount() -> Bool {

        let user = getConsoleUser()
        guard let dsRecord =  try? PasswordUtils.getLocalRecord(user) else {
            return false
        }
        let kerbPrinc = try? dsRecord.values(forAttribute:"dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal" )

        let kerbPrincPrefs = UserDefaults.standard.string(forKey:"_xcreds_activedirectory_kerberosPrincipal" )

        let oidcUsername = try? dsRecord.values(forAttribute:"dsAttrTypeNative:_xcreds_oidc_username" )

        let oidcUsernamePrefs = UserDefaults.standard.string(forKey:"_xcreds_oidc_username" )


        if kerbPrinc == nil && oidcUsername == nil && kerbPrincPrefs == nil && oidcUsernamePrefs == nil {
            TCSLogWithMark("no kerberos principal and no oidc username in local DS console user, so skipping showing window")
            return true

        }
        return false

    }
    func showSignInWindow(force:Bool=false, forceLoginWindowType:LoginWindowType?=nil )  {
        TCSLogWithMark()

        if isLocalOnlyAccount()==true && force==false{
            TCSLogWithMark()
            return
        }


        if  let webViewController = windowController.webViewController{
            TCSLogWithMark()
            webViewController.webView.isHidden=true
        }

        //put the timers off some we don't get mutiple other prompts when user is putting in credentials
        scheduleManager.setNextCheckTime(timer: .ADTimer )
        scheduleManager.setNextCheckTime(timer: .TokenTimer)

        var forceUsernamePassword = false

        if let forceLoginWindowType = forceLoginWindowType {
            TCSLogWithMark()
            if forceLoginWindowType == .usernamePassword {
                TCSLogWithMark()
                forceUsernamePassword = true
            }
        }
        if forceUsernamePassword == false,
           DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue) != nil,
            DefaultsOverride.standardOverride.value(forKey: PrefKeys.clientID.rawValue) != nil ,
            DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseROPGForMenuLogin.rawValue) == false  {
            TCSLogWithMark()
            let tokenManager = TokenManager()
            if tokenManager.endpointsAvailable() == false {
                return
            }
            guard  let window = windowController.window else            {
                return

            }

            window.makeKeyAndOrderFront(self)

            if  let webViewController = windowController.webViewController{
                webViewController.webView.isHidden=false
                TCSLogWithMark()
                windowController.webViewController.updateCredentialsFeedbackDelegate=self
                windowController.webViewController?.loadPage()
            }
            NSApp.activate(ignoringOtherApps: true)

        }

        else if (DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseROPGForMenuLogin.rawValue) == true || DefaultsOverride.standardOverride.value(forKey: PrefKeys.aDDomain.rawValue) != nil )
        {
            if let webView = windowController.webViewController?.webView {
                webView.isHidden=true
                TCSLogWithMark()
            }

            if let window = windowController.window{
                let bundle = Bundle.findBundleWithName(name: "XCreds")
                if let bundle = bundle{
                    TCSLogWithMark("Creating signInViewController")
                    if signInViewController == nil {
                        signInViewController = SignInViewController(nibName: "LocalUsersViewController", bundle:bundle)
                    }
                    TCSLogWithMark()
                    signInViewController?.isInUserSpace = true
                    signInViewController?.updateCredentialsFeedbackDelegate=self
                    guard let signInViewController = signInViewController else {
                        return
                    }

                    if let contentView = window.contentView {
                        TCSLogWithMark()
                        windowController.webViewController.webView.isHidden=true
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
                        signInViewController.localOnlyCheckBox.isHidden = true

                        signInViewController.view.setFrameOrigin(lowerLeftCorner)
                    }

                    window.makeKeyAndOrderFront(self)
                    NSApp.activate(ignoringOtherApps: true)

                }
            }
        }

    }

    func checkAndMountShares() {

        let tickets = KlistUtil().returnTickets()
        if tickets.count>0{
            let appDelegate = NSApp.delegate as? AppDelegate

            appDelegate?.shareMounterMenu?.updateShares(connected: true, tickets: true)
        }

    }
    func setup() {
        if let cloudPasswordExpiresDate = OIDCPasswordExpiryDate(){

            if OIDCPasswordExpiryDate()?.timeIntervalSinceNow ?? 0<0 {
                self.cloudPasswordExpires = "Password Expired!"
                return
            }
            if #available(macOS 12.0, *) {
                self.cloudPasswordExpires=cloudPasswordExpiresDate.formatted(date: .abbreviated, time: .shortened)
            } else {
                self.cloudPasswordExpires=cloudPasswordExpiresDate.debugDescription
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didUnmountNotification, object: nil, queue: nil) { notification in
                self.scheduleManager.checkKerberosTicket()
                self.checkAndMountShares()

        }

        NotificationCenter.default.addObserver(forName: .connectivityStatus, object: nil, queue: nil) { notification in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+10) {
                self.scheduleManager.checkKerberosTicket()
                self.checkAndMountShares()
            }
        }
        self.checkAndMountShares()
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
        let shouldShowMenuBarSignInWithoutLoginWindowSignin = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowMenuBarSignInWithoutLoginWindowSignin.rawValue)

        if shouldShowMenuBarSignInWithoutLoginWindowSignin == true {
            showSignInWindow(force:true,forceLoginWindowType: .cloud)
        }


    }

    //get local password either from keychain or prompt. If prompt, then it will save in keychain for next time. if keychain, get keychain and test to make sure it is valid.
    func localAccountAndPassword() -> (String?,String?) {

        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldSuppressLocalPasswordPrompt.rawValue)==true {
            return (nil,nil)

        }

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
            let err = keychainUtil.updatePassword(serviceName: "xcreds local password",accountName:accountName, pass:localPassword, shouldUpdateACL: true, keychainPassword: localPassword)
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
    func passwordExpiryUpdate(_ passwordExpire: Date) {
        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: passwordExpire)


        if passwordExpire.timeIntervalSinceNow>10*365*24*60*60{
            self.adPasswordExpires="Never"
        }
        else {
            self.adPasswordExpires=dateString

        }


        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.updateStatusMenuExpiration(passwordExpire)


    }


    func credentialsUpdated(_ credentials:Creds) {
        hasCredential=true
        credentialStatus="Valid Tokens"
        (NSApp.delegate as? AppDelegate)?.updateStatusMenuIcon(showDot:true)
        let tokenManager = TokenManager()

        if  let idTokenInfo = try? tokenManager.tokenInfo(fromCredentials: credentials){
            let userInfoResult = tokenManager.setupUserAccountInfo(idTokenInfo: idTokenInfo)

            switch userInfoResult {

            case .success(let retUserAccountInfo):
                let userInfo = retUserAccountInfo
                if let username = userInfo.username {
                    UserDefaults.standard.set(username, forKey:"_xcreds_oidc_username")
                }
                if let fullUsername = userInfo.fullUsername {
                    UserDefaults.standard.set(fullUsername, forKey:"_xcreds_oidc_full_username")
                }
                if let kerberosPrincipalName = userInfo.kerberosPrincipalName {
                    UserDefaults.standard.set(kerberosPrincipalName, forKey:"_xcreds_activedirectory_kerberosPrincipal")
                }
            case .error(let message):
                TCSLogWithMark("Error getting infoResult: \(message)")
            }

        }
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
            var localPassword = credentials.password
            if localPassword==nil {
                localPassword = localAccountAndPassword.1
            }
            if TokenManager.saveTokensToKeychain(creds: credentials, setACL: true, password:localPassword ) == false {
                TCSLogErrorWithMark("error saving tokens to keychain")
            }

            self.scheduleManager.startCredentialCheck()

        }

        //delay startup to give network time to settle.
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { timer in
            self.scheduleManager.startCredentialCheck()
        }

    }
    func invalidCredentials() {
        TCSLogWithMark()
        hasCredential=false
        credentialStatus="Invalid Credentials"
        let appDelegate = NSApp.delegate as? AppDelegate

        appDelegate?.updateStatusMenuIcon(showDot:false)

        showSignInWindow(forceLoginWindowType: .cloud)



    }
    func credentialsCheckFailed() {
        TCSLogWithMark()
        hasCredential=false
        credentialStatus="Credentials Check Failed"
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.updateStatusMenuIcon(showDot:false)
            showSignInWindow(forceLoginWindowType: .cloud)

    }
    func kerberosTicketUpdated() {
        TCSLogWithMark()
        hasKerberosTicket=true
        (NSApp.delegate as? AppDelegate)?.updateStatusMenuIcon(showDot:true)

        credentialStatus="Valid kerberos tickets"
    }
    func kerberosTicketCheckFailed(_ error: NoMADSessionError) {

        TCSLogWithMark()
        hasKerberosTicket=false
        (NSApp.delegate as? AppDelegate)?.updateStatusMenuIcon(showDot:false)

        credentialStatus="Kerberos Tickets Failed"
        switch error{

        case .OffDomain:
            TCSLogWithMark("Off domain so not prompting")

        case .UnknownPrincipal:
            TCSLogWithMark("UnknownPrincipal so not prompting")

        default:
            showSignInWindow(forceLoginWindowType: .usernamePassword)

        }
    }
    func adUserUpdated(_ adUser: ADUserRecord) {

        (NSApp.delegate as? AppDelegate)?.updateShareMenu(adUser: adUser)

    }
    func OIDCPasswordExpiryDate() -> Date?{

        let keychainUtil = KeychainUtil()

        guard let idToken = try? keychainUtil.findPassword(serviceName: "xcreds idToken", accountName: "idToken").1 else {
            TCSLogWithMark("cannot find ID token")

            return nil
        }

        let idTokenInfo = jwtDecode(value: idToken)  //dictionary for mapping

        guard let idTokenInfo = idTokenInfo else {
            TCSLogWithMark("idTokenInfo invalid")
            return nil
        }

        guard let expiryKey = DefaultsOverride.standardOverride.object(forKey: PrefKeys.mapPasswordExpiry.rawValue)  as? String,
              expiryKey.count>0,
              let expiryString = idTokenInfo[expiryKey] as? String,
              let expiryNumber = Int(expiryString) else {
            TCSLogWithMark("mapPasswordExpiry invalid")

            return nil
        }

        guard let iatInt = idTokenInfo["iat"] as? Int
              else {
            TCSLogWithMark("iatInt invalid")

            return nil
        }
        TCSLogWithMark("iatInt: \(iatInt)")
        TCSLogWithMark("expiryNumber: \(expiryNumber)")

        let expirySecondsFromEpoch = expiryNumber + iatInt
        TCSLogWithMark("expirySecondsFromEpoch: \(expirySecondsFromEpoch)")

        let expiryDate = Date(timeIntervalSince1970: TimeInterval(expirySecondsFromEpoch))

        TCSLogWithMark("expiryDate: \(expiryDate)")

        return expiryDate

    }


}

