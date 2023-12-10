//
//  LoginPasswordWindowController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//

import Cocoa

class PromptForLocalPasswordWindowController: NSWindowController {

    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var resetButton: NSButton!

    var password:String?
    var resetKeychain = false
    enum RequestLocalPasswordResult {
        case success(String)
        case resetKeychain
        case cancelled
        case error(String)

    }
    static func verifyLocalPasswordAndChange(username:String, password:String?, shouldUpdatePassword:Bool) -> RequestLocalPasswordResult {
        let passwordWindowController = PromptForLocalPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))

        passwordWindowController.window?.canBecomeVisibleWithoutLogin=true
        passwordWindowController.window?.isMovable = false
        passwordWindowController.window?.canBecomeVisibleWithoutLogin = true
        passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)

        var isDone = false
        while (!isDone){
            DispatchQueue.main.async{
                TCSLogWithMark("resetting level")
                passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
            }

            let response = NSApp.runModal(for: passwordWindowController.window!)
            if response == .cancel {
                isDone=true
                TCSLogWithMark("User cancelled resetting keychain or entering password. Denying login")
//                mechanism.denyLogin(message:nil)
                return .cancelled

            }
            let resetKeychain = passwordWindowController.resetKeychain

            if resetKeychain == true {
                passwordWindowController.window?.close()
                isDone=true
                return .resetKeychain

            }
            else {
                TCSLogWithMark("user gave old password. checking...")
                let localPassword = passwordWindowController.password
                guard let localPassword = localPassword else {
                    continue
                }

                let isValidPassword = PasswordUtils.isLocalPasswordValid(userName: username, userPass: localPassword)
                switch isValidPassword {
                case .success:
                    let localUser = try? PasswordUtils.getLocalRecord(username)
                    guard let localUser = localUser else {
                        TCSLogErrorWithMark("invalid local user")
                        return .error("The local user \(username) could not be found")
                    }
                    if shouldUpdatePassword==false {

                        return .success(localPassword)
                    }
                    guard let password = password else {
                        return .error("Password not provided for changing")

                    }

                    do {
                        try localUser.changePassword(localPassword, toPassword: password)
                    }
                    catch {
                        TCSLogErrorWithMark("Error setting local password to cloud password")

                        return .error("Error setting local password to cloud password: \(error.localizedDescription)")
                    }
                    TCSLogWithMark("setting original password to use to unlock keychain later")
                    isDone=true
                    passwordWindowController.window?.close()
                    return .success(localPassword)
                default:
                    passwordWindowController.window?.shake(self)

                }
            }
        }
    }

    
    override func windowDidLoad() {
        super.windowDidLoad()
        TCSLogWithMark()
        if DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue) != nil &&
            DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue) != nil
        {
            resetButton.isHidden=false
        }
        else {
            resetButton.isHidden=true

        }

    }
  

    @IBAction func removeKeychainButtonPressed(_ sender: Any) {
        if self.window?.isModalPanel==true {
            resetKeychain=true
            NSApp.stopModal(withCode: .OK)

        }


    }
    @IBAction func updateButtonPressed(_ sender: Any) {
        if self.window?.isModalPanel==true {
            password=passwordTextField.stringValue
            NSApp.stopModal(withCode: .OK)

        }
    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if self.window?.isModalPanel==true {
            NSApp.stopModal(withCode: .cancel)
        }
    }
}
