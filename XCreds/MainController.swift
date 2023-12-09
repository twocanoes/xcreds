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
    }


    var session:NoMADSession?
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
        let accountAndPassword = localAccountAndPassword()


        if let userName=accountAndPassword.0, let passString = accountAndPassword.1, passString.isEmpty==false{

            if let domainName = userName.components(separatedBy: "@").last, let shortName = userName.components(separatedBy: "@").first, domainName.isEmpty==false, shortName.isEmpty==false{
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
                    //                os_log("Ignoring AD sites", log: uiLog, type: .debug)

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

        NotificationCenter.default.addObserver(forName: Notification.Name("TCSTokensUpdated"), object: nil, queue: nil) { notification in


            DispatchQueue.main.async {
//                mainMenu.webView?.window?.close()

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
                    mainMenu.statusBarItem.button?.image=NSImage(named: "xcreds menu icon check")
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
        let passwordWindowController = LoginPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))
        
        TCSLogWithMark()
        while (true){
            TCSLogWithMark()
            NSApp.activate(ignoringOtherApps: true)
            let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
                NSApp.activate(ignoringOtherApps: true)

            }
            TCSLogWithMark()
            let response = NSApp.runModal(for: passwordWindowController.window!)

            timer.invalidate()
            if response == .cancel {
                break
            }
            if passwordWindowController.resetKeychain==true {
                return (nil,nil)
            }
            let localPassword = passwordWindowController.password
            guard let localPassword = localPassword else {
                continue
            }
            let isPasswordValid = PasswordUtils.verifyCurrentUserPassword(password:localPassword )
            if isPasswordValid==true {
                passwordWindowController.window?.close()
                let err = keychainUtil.updatePassword(serviceName: "xcreds local password",accountName:accountName, pass: localPassword, shouldUpdateACL: true)
                if err == false {
                    return (nil,nil)
                }
                return (accountName,localPassword)
            }
            else{
                passwordWindowController.window?.shake(self)
            }
        }

        return (nil,nil)
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
