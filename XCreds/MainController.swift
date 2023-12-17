//
//  MainController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa
import NoMAD_ADAuth
class MainController: NSObject, NoMADUserSessionDelegate {
    func NoMADAuthenticationSucceded() {
        session?.userInfo()

    }

    func NoMADAuthenticationFailed(error: NoMAD_ADAuth.NoMADSessionError, description: String) {
        TCSLogErrorWithMark("NoMADAuthenticationFailed:\(description)")
    }
    
    func NoMADUserInformation(user: NoMAD_ADAuth.ADUserRecord) {
        TCSLogWithMark("AD user password expires: \(user.passwordExpire?.description ?? "unknown")")


        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        if let passExpired = user.passwordExpire {
            let dateString = dateFormatter.string(from: passExpired)
            sharedMainMenu.passwordExpires="Password Expires: \(dateString)"
        }
    }


    var passwordCheckTimer:Timer?
    var session:NoMADSession?
    func checkPasswordExpire() {
        let accountAndPassword = localAccountAndPassword()

        let domainName = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aDDomain.rawValue)

        if let userName=accountAndPassword.0, let passString = accountAndPassword.1, passString.isEmpty==false{

            if let domainName = domainName, let shortName = userName.components(separatedBy: "@").first, domainName.isEmpty==false, shortName.isEmpty==false{
                session = NoMADSession.init(domain: domainName, user: shortName)
                TCSLogWithMark("NoMAD Login User: \(shortName), Domain: \(domainName)")
                guard let session = session else {
                    TCSLogErrorWithMark("Could not create NoMADSession from SignIn window")
                    return
                }
                session.useSSL = getManagedPreference(key: .LDAPOverSSL) as? Bool ?? false
                session.userPass = passString
                session.delegate = self
                session.recursiveGroupLookup = getManagedPreference(key: .RecursiveGroupLookup) as? Bool ?? false

                if let ignoreSites = getManagedPreference(key: .IgnoreSites) as? Bool {

                    session.siteIgnore = ignoreSites
                }

                if let ldapServers = getManagedPreference(key: .LDAPServers) as? [String] {
                    TCSLogWithMark("Adding custom LDAP servers")

                    session.ldapServers = ldapServers
                }

                TCSLogWithMark("Attempt to authenticate user")
                session.authenticate()
            }
        }

    }
    func run() -> Void {

        TCSLogWithMark()
        let defaultsPath = Bundle.main.path(forResource: "defaults", ofType: "plist")

        if let defaultsPath = defaultsPath {

            let defaultsDict = NSDictionary(contentsOfFile: defaultsPath)
            TCSLogWithMark()
            DefaultsOverride.standardOverride.register(defaults: defaultsDict as! [String : Any])
        }
        

        // make sure we have the local password, else prompt. we don't need to save it
        // just make sure we prompt if not in the keychain. if the user cancels, then it will
        // prompt when using OAuth.
        // don't need to save it. just need to prompt and it gets saved
        // in the keychain

        let domainName = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aDDomain.rawValue)

        if let _ = domainName, passwordCheckTimer == nil {
            checkPasswordExpire()
            passwordCheckTimer = Timer.scheduledTimer(withTimeInterval: 3*60*60, repeats: true, block: { _ in
                self.checkPasswordExpire()
            })

        }
        NotificationCenter.default.addObserver(forName: Notification.Name("TCSTokensUpdated"), object: nil, queue: nil) { notification in


            DispatchQueue.main.async {
                sharedMainMenu.windowController.window?.close()

                guard let tokenInfo = notification.userInfo else {
                    return
                }

                guard let tokens = tokenInfo["tokens"] as? Creds else {
                    let alert = NSAlert()
                    alert.addButton(withTitle: "OK")
                    alert.messageText="Invalid tokens or password not determined. Please check the log."
                    alert.runModal()
                    return
                }
                if let refreshToken = tokens.refreshToken, refreshToken.count>0 {
                    //                    Mark()
                    sharedMainMenu.statusBarItem.button?.image=NSImage(named: "xcreds menu icon check")
                }
                let localAccountAndPassword = self.localAccountAndPassword()
                if var localPassword=localAccountAndPassword.1{
                    if (localPassword != tokens.password){
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
                                    alert.messageText="Are you sure you want to skip updating the local password and keychain? You local password and keychain will be out of sync with your cloud password. "
                                    let resp = alert.runModal()
                                    if resp == .alertFirstButtonReturn {
                                        NSApp.stopModal(withCode: .cancel)
                                        verifyOIDPassword.window?.close()
                                        updatePassword=false
                                        break

                                    }
                                }
                                let verifyCloudPassword = verifyOIDPassword.password
                                if verifyCloudPassword == tokens.password {

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
                            let updatedLocalAccountAndPassword = self.localAccountAndPassword()
                            if let updatedLocalPassword = updatedLocalAccountAndPassword.1{
                                localPassword=updatedLocalPassword
                                try? PasswordUtils.changeLocalUserAndKeychainPassword(updatedLocalPassword, newPassword1: tokens.password, newPassword2: tokens.password)
                            }


                        }
                    }
                }
                if TokenManager.shared.saveTokensToKeychain(creds: tokens, setACL: true, password:tokens.password ) == false {
                    TCSLogErrorWithMark("error saving tokens to keychain")
                }
                ScheduleManager.shared.startCredentialCheck()

            }
        }
        //delay startup to give network time to settle.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            ScheduleManager.shared.startCredentialCheck()
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
//        let passwordWindowController = LoginPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))
        let promptPasswordWindowController = PromptForLocalPasswordWindowController()

        
        promptPasswordWindowController.showResetText=false
        promptPasswordWindowController.showResetButton=false

        switch  promptPasswordWindowController.verifyLocalPasswordAndChange(username: PasswordUtils.currentConsoleUserName, password: nil, shouldUpdatePassword: false) {

        case .success(let localPassword):
            let err = keychainUtil.updatePassword(serviceName: "xcreds local password",accountName:accountName, pass: localPassword, shouldUpdateACL: true)
            if err == false {
                return (nil,nil)
            }
            return (accountName,localPassword)

        case .resetKeychain:
            return (nil,nil)

        case .cancelled:
            return (nil,nil)
        case .error(_):
            return (nil,nil)

        }

    }
}


/*
 if let password = password {

 NotifyManager.shared.sendMessage(message: "valid password")
 }
 else {
 NotifyManager.shared.sendMessage(message: "cancelled")
 }

 */
