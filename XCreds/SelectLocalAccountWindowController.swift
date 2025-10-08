//
//  VerifyLocalCredentialsWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 11/25/23.
//

import Cocoa

class SelectLocalAccountWindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak private var usernameTextField: NSTextField!
    @IBOutlet weak private var passwordTextField: NSSecureTextField!
    @IBOutlet weak private var createNewAccountButton: NSButton!

    var username:String?
    var password:String?
    var shouldCreateNewAccount:Bool?=false
    var shouldShowCreateNewAccountButton:Bool?=true

    enum VerifyLocalCredentialsResult {
        case successful(String)
        case canceled
        case createNewAccount
        case error(String)
    }
    static func selectLocalAccountAndUpdate(newPassword:String) -> VerifyLocalCredentialsResult{
        let verifyLocalCredentialsWindowController = SelectLocalAccountWindowController.init(windowNibName: NSNib.Name("SelectLocalAccountWindowController"))
        verifyLocalCredentialsWindowController.window?.canBecomeVisibleWithoutLogin=true
        verifyLocalCredentialsWindowController.window?.isMovable = false
        verifyLocalCredentialsWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
        var isDone = false
        while (!isDone){
            DispatchQueue.main.async{
                TCSLogWithMark("resetting level")
                verifyLocalCredentialsWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
            }

            let response = NSApp.runModal(for: verifyLocalCredentialsWindowController.window!)
            verifyLocalCredentialsWindowController.window?.close()
            if response == .cancel {
                isDone=true
                TCSLogWithMark("User cancelled. Denying login")
//                mechanism.denyLogin(message:nil)
                return .canceled

            }
            let localUsername = verifyLocalCredentialsWindowController.username
            let localPassword = verifyLocalCredentialsWindowController.password
            let shouldCreateNewAccount = verifyLocalCredentialsWindowController.shouldCreateNewAccount


            guard let localUsername = localUsername, let localPassword = localPassword, let shouldCreateNewAccount = shouldCreateNewAccount else {
                TCSLogWithMark("local username, password or shouldCreateNewAccount not set")
//                mechanism.denyLogin(message:nil)
                return .canceled
            }
            if shouldCreateNewAccount == false {
                let isValidPassword = PasswordUtils.isLocalPasswordValid(userName: localUsername, userPass: localPassword)
                switch isValidPassword {
                case .success:
                    isDone = true
                   let localUser = try? PasswordUtils.getLocalRecord(localUsername)
                    guard let localUser = localUser else {

                        isDone = true
                        TCSLogErrorWithMark("localUser is not set")
                        return .error("local user not set")

                    }
                    do {
                        TCSLogWithMark("Changing password")
                        if localPassword == newPassword {
                            TCSLogWithMark("cloud password is already the local password.")

                            return .successful(localUsername)
                        }
                        try localUser.changePassword(localPassword, toPassword: newPassword)

                        TCSLogWithMark("local password set successfully to network / cloud password")
                        return .successful(localUsername)

                    }
                    catch {
                        TCSLogErrorWithMark("Error setting local password to cloud password")
                        return .error("Error setting local password to cloud password")
                    }

                case .accountLocked:
                    TCSLogErrorWithMark("Account Locked")
                case .incorrectPassword: //don't return b/c we just loop and ask again
                    TCSLogErrorWithMark("Incorrect Password")

                case .accountDoesNotExist:
                    TCSLogErrorWithMark("Account \(localUsername) does not exist")

                case .other(let err):
                    isDone = true
                    TCSLogErrorWithMark("Other err: \(err)")
                    return .error(err)


                }
            }
            else {
                isDone = true
                return .createNewAccount
            }
        }

    }
    override func windowDidLoad() {
        super.windowDidLoad()
        if let shouldShowCreateNewAccountButton = shouldShowCreateNewAccountButton{
            createNewAccountButton.isHidden = !shouldShowCreateNewAccountButton
        }

    }
    func windowDidBecomeKey(_ notification: Notification) {
        if let shouldShowCreateNewAccountButton = shouldShowCreateNewAccountButton{
            createNewAccountButton.isHidden = !shouldShowCreateNewAccountButton
        }

    }

    @IBAction func okButtonPressed(_ sender: Any) {
        if self.window?.isModalPanel==true {
            username = usernameTextField.stringValue
            password=passwordTextField.stringValue
            NSApp.stopModal(withCode: .OK)

        }

    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if self.window?.isModalPanel==true {
            NSApp.stopModal(withCode: .cancel)
        }

    }
    @IBAction func createNewAccountButtonPressed(_ sender: Any) {
        shouldCreateNewAccount=true
        username = ""
        password = ""
        if self.window?.isModalPanel==true {
            NSApp.stopModal(withCode: .OK)

        }
    }
}
