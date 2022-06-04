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
                if let userInfo = notification.userInfo, let newPassword = userInfo["password"] as? String {
                    let password = self.localPassword()

                    if let password = password {
                        try? PasswordUtils.changeLocalUserAndKeychainPassword(password, newPassword1: newPassword, newPassword2: newPassword)
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
        while (true){

            let alertController = NSAlert()

            alertController.messageText = "Please enter your local password"
            alertController.addButton(withTitle: "OK")
            alertController.addButton(withTitle: "Cancel")

            let localPassword = NSSecureTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 24))

            alertController.accessoryView = localPassword
            localPassword.becomeFirstResponder()

            let response = alertController.runModal()


            if response == .alertSecondButtonReturn {
                break
            }
            let isPasswordValid = PasswordUtils.verifyCurrentUserPassword(password: localPassword.stringValue)
            if isPasswordValid==true {
                let err = keychainUtil.setPassword("xcreds", pass: localPassword.stringValue)
                if err != OSStatus(errSecSuccess) {
                    return nil
                }
                return localPassword.stringValue
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
