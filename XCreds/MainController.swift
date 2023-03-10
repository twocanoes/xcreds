//
//  MainController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa

class MainController: NSObject {
    func run() -> Void {

        let defaultsPath = Bundle.main.path(forResource: "defaults", ofType: "plist")

        if let defaultsPath = defaultsPath {

            let defaultsDict = NSDictionary(contentsOfFile: defaultsPath)
            UserDefaults.standard.register(defaults: defaultsDict as! [String : Any])
        }
        

        // make sure we have the local password, else prompt. we don't need to save it
        // just make sure we prompt if not in the keychain. if the user cancels, then it will
        // prompt when using OAuth.
        // don't need to save it. just need to prompt and it gets saved
        // in the keychain
        let _ = localPassword()
        NotificationCenter.default.addObserver(forName: Notification.Name("TCSTokensUpdated"), object: nil, queue: nil) { notification in


//            //now we set the password.
             Mark()
            DispatchQueue.main.async {
                mainMenu.webView?.window?.close()

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
                    Mark()
                    mainMenu.statusBarItem.button?.image=NSImage(named: "xcreds menu icon check")
                }
                let localPassword = self.localPassword()
                if (localPassword != tokens.password){
                    var updatePassword = true
                    if UserDefaults.standard.bool(forKey: PrefKeys.verifyPassword.rawValue)==true {
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
                        guard let localPassword = self.localPassword() else {
                            TCSLogWithMark("error getting local password")
                            return
                        }
                        try? PasswordUtils.changeLocalUserAndKeychainPassword(localPassword, newPassword1: tokens.password, newPassword2: tokens.password)


                    }
                }
                if TokenManager.shared.saveTokensToKeychain(creds: tokens, setACL: true, password:tokens.password ) == false {
                    TCSLogWithMark("error saving tokens to keychain")
                }
                ScheduleManager.shared.startCredentialCheck()

            }
        }
        ScheduleManager.shared.startCredentialCheck()
    }

    //get local password either from keychain or prompt. If prompt, then it will save in keychain for next time. if keychain, get keychain and test to make sure it is valid.
    func localPassword() -> String? {
        let keychainUtil = KeychainUtil()

        let password = try? keychainUtil.findPassword(PrefKeys.password.rawValue)

        if let password = password {
            if PasswordUtils.verifyCurrentUserPassword(password: password) == true {
                return password
            }
        }
        let passwordWindowController = LoginPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))


        while (true){
            
            NSApp.activate(ignoringOtherApps: true)
            let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
                NSApp.activate(ignoringOtherApps: true)

            }

            let response = NSApp.runModal(for: passwordWindowController.window!)

            timer.invalidate()
            if response == .cancel {
                break
            }
            let localPassword = passwordWindowController.password
            guard let localPassword = localPassword else {
                continue
            }
            let isPasswordValid = PasswordUtils.verifyCurrentUserPassword(password:localPassword )
            if isPasswordValid==true {
                passwordWindowController.window?.close()
                let err = keychainUtil.updatePassword(PrefKeys.password.rawValue, pass: localPassword, shouldUpdateACL: true)
                if err == false {
                    return nil
                }
                return localPassword
            }
            else{
                passwordWindowController.window?.shake(self)
            }
        }

        return nil
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
