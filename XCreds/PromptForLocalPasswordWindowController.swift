//
//  LoginPasswordWindowController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//

import Cocoa

class PromptForLocalPasswordWindowController: NSWindowController, DSQueryable {

    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var adminUsernameTextField: NSTextField!
    @IBOutlet weak var adminPasswordTextField: NSSecureTextField!
    @IBOutlet weak var adminCredentialsWindow: NSWindow!


    @IBOutlet weak var resetButton: NSButton!

    var shouldPromptForAdmin=false
    var password:String?
    var resetKeychain = false
    var adminUsername:String?
    var adminPassword:String?

    enum RequestLocalPasswordResult {
        case success(String)
        case resetKeychain(String?,String?)
        case cancelled
        case error(String)

    }
    static func verifyLocalPasswordAndChange(username:String, password:String?, shouldUpdatePassword:Bool) -> RequestLocalPasswordResult {
        let passwordWindowController = PromptForLocalPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))

        passwordWindowController.window?.canBecomeVisibleWithoutLogin=true
        passwordWindowController.window?.isMovable = true
        passwordWindowController.window?.canBecomeVisibleWithoutLogin = true
        passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)

        var isDone = false
        while (!isDone){
            DispatchQueue.main.async{
                TCSLogWithMark("resetting level")
                passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
            }

            let response = NSApp.runModal(for: passwordWindowController.window!)
            passwordWindowController.window?.close()

            if response == .cancel {
                isDone=true
                TCSLogWithMark("User cancelled resetting keychain or entering password. Denying login")
                return .cancelled

            }
            //set if user clicked reset
            let resetKeychain = passwordWindowController.resetKeychain

            if resetKeychain == true { //user clicked reset
                isDone=true

                return .resetKeychain(passwordWindowController.adminUsername, passwordWindowController.adminPassword)

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
//        if DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue) != nil &&
//            DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue) != nil
//        {
//            resetButton.isHidden=false
//        }
//        else {
//            resetButton.isHidden=true
//
//        }

    }
  

    @IBAction func removeKeychainButtonPressed(_ sender: Any) {


        //override or prefs has admin username / password so don't prompt
        if DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue) != nil &&
            DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue) != nil {
            if self.window?.isModalPanel==true {
                resetKeychain=true
                NSApp.stopModal(withCode: .OK)

            }

        }
        else { //prompt
            self.adminCredentialsWindow?.canBecomeVisibleWithoutLogin = true

            self.window?.beginSheet(adminCredentialsWindow) { res in
                if res == .OK {
                    self.resetKeychain=true
                    TCSLogWithMark("got admin username and password")
                    self.window?.endSheet(self.adminCredentialsWindow)

                    if self.window?.isModalPanel==true {
                        TCSLogWithMark("Prompt for local password window is modal so stopping")

                        NSApp.stopModal(withCode: .OK)
                    }



                }
                else { //user hit cancel
                    TCSLogWithMark("cancelled admin")
                    self.window?.endSheet(self.adminCredentialsWindow)
                }
            }
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

    @IBAction func adminCancelButtonPressed(_ sender: Any) {

        window?.endSheet(adminCredentialsWindow, returnCode: .cancel)

    }
    @IBAction func adminResetButtonPressed(_ sender: Any) {
        self.adminUsername=nil
        self.adminPassword=nil
        let adminUserName = adminUsernameTextField.stringValue
        let adminPassword = adminPasswordTextField.stringValue

        if adminUserName == "" {

            adminUsernameTextField.shake(self)
            return
        }

        else if adminPassword == "" {
            adminPasswordTextField.shake(self)
            return

        }
        let user = try? getLocalRecord(adminUserName)

        if user == nil {

            adminUsernameTextField.shake(self)
            return
        }
        if PasswordUtils.verifyUser(name: adminUserName, auth: adminPassword)==false {
            adminPasswordTextField.shake(self)
            return
        }
        else { //password is valid

            self.adminUsername=adminUserName
            self.adminPassword=adminPassword


            window?.endSheet(adminCredentialsWindow, returnCode: .OK)
        }
    }


}
