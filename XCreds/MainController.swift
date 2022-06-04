//
//  MainController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa

class MainController: NSObject {
    func run() -> Void {
        // make sure we have the local password, else prompt. we don't need to save it
        // just make sure we prompt if not in the keychain. if the user cancels, then it will
        // prompt when using OAuth.
        let _ = localPassword()
        NotificationCenter.default.addObserver(forName: Notification.Name("TCSTokensUpdated"), object: nil, queue: nil) { notification in
            //now we set the password.

            DispatchQueue.main.async {
                if let userInfo = notification.userInfo, let cloudPassword = userInfo["password"] as? String {
                    let localPassword = self.localPassword()

                    if let localPassword = localPassword {
                        let verifyOIDPassword = VerifyOIDCPassword.init(windowNibName: NSNib.Name("VerifyOIDCPassword"))
                        NSApp.activate(ignoringOtherApps: true)

                        while true {
                            let response = NSApp.runModal(for: verifyOIDPassword.window!)
                            if response == .cancel {
                                verifyOIDPassword.window?.close()
                                break
                            }
                            let verifyCloudPassword = verifyOIDPassword.password

                            if verifyCloudPassword == cloudPassword {
                                try? PasswordUtils.changeLocalUserAndKeychainPassword(localPassword, newPassword1: cloudPassword, newPassword2: cloudPassword)
                                verifyOIDPassword.window?.close()
                                break;

                            }
                            else {
                                verifyOIDPassword.window?.shake(self)
                            }

                        }


                    }

                    ScheduleManager.shared.startCredentialCheck()
                }
            }
        }
        ScheduleManager.shared.startCredentialCheck()

    }

    //get local password either from keychain or prompt. If prompt, then it will save in keychain for next time. if keychain, get keychain and test to make sure it is valid.
    func localPassword() -> String? {
        let keychainUtil = KeychainUtil()

        let password = try? keychainUtil.findPassword("xcreds")

        if let password = password {
            if PasswordUtils.verifyCurrentUserPassword(password: password) == true {
                return password
            }
        }
        let passwordWindowController = LoginPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))


        while (true){
            NSApp.activate(ignoringOtherApps: true)
            let response = NSApp.runModal(for: passwordWindowController.window!)

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
                let err = keychainUtil.setPassword("xcreds", pass: localPassword)
                if err != OSStatus(errSecSuccess) {
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
