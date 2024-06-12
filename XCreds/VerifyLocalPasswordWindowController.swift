//
//  LoginPasswordWindowController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//

import Cocoa

class VerifyLocalPasswordWindowController: NSWindowController, DSQueryable {

    struct UsernamePasswordCredentials {
        var username:String?
        var password:String?
    }
    

    enum LocalUsernamePasswordResult {
        case success(UsernamePasswordCredentials?)
        case resetKeychainRequested(UsernamePasswordCredentials?)
        case userCancelled
        case error(String)
    }


    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var adminUsernameTextField: NSTextField!
    @IBOutlet weak var adminPasswordTextField: NSSecureTextField!
    @IBOutlet weak var adminCredentialsWindow: NSWindow!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var resetText: NSTextField!
    @IBOutlet weak var resetTitle: NSTextField!

    @IBOutlet weak var usernameTextField: NSTextField!
    var showResetButton = true
    var showResetText = true
    var shouldPromptForAdmin=false
    var passwordEntered:String?
    var resetKeychain = false
    var adminUsername:String?
    var adminPassword:String?
    var currentUsername:String?

    override var windowNibName: NSNib.Name {

        return "VerifyLocalPasswordWindowController"
    }
    override func awakeFromNib() {
        resetButton.isHidden = !showResetButton
        resetText.isHidden = !showResetText
        if let currentUsername = currentUsername {
            usernameTextField.stringValue = currentUsername
        }

        if let resetPasswordDialogTitle = DefaultsOverride.standardOverride.string(forKey: PrefKeys.resetPasswordDialogTitle.rawValue), resetPasswordDialogTitle.count>0{

            resetTitle.stringValue=resetPasswordDialogTitle
        }

    }
    func promptForLocalAccountAndChangePassword(username:String, newPassword:String?, shouldUpdatePassword:Bool) -> LocalUsernamePasswordResult {
        currentUsername = username
        if newPassword == nil {
         TCSLogWithMark("new password is nil")
        }
        window?.canBecomeVisibleWithoutLogin=true
        window?.isMovable = true
        window?.canBecomeVisibleWithoutLogin = true
        window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)

        var isDone = false
        while (!isDone){
            DispatchQueue.main.async{
                TCSLogWithMark("resetting level")
                self.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
            }

            let response = NSApp.runModal(for: window!)
            window?.close()

            if response == .cancel {
                isDone=true
                TCSLogWithMark("User cancelled resetting keychain or entering password.")
                return .userCancelled

            }
            if resetKeychain == true { //user clicked reset
                isDone=true

                return .resetKeychainRequested(UsernamePasswordCredentials(username: adminUsername, password: adminPassword))

            }
            else {
                TCSLogWithMark("user gave old password. checking...")
                let passwordEntered = self.passwordEntered
                guard let passwordEntered = passwordEntered else {
                    TCSLogWithMark("No password entered, looping...")

                    continue
                }

                let isValidPassword = PasswordUtils.isLocalPasswordValid(userName: username, userPass: passwordEntered)
                switch isValidPassword {
                case .success:
                    TCSLogWithMark("Password check successful")
                    let localUser = try? PasswordUtils.getLocalRecord(username)
                    guard let localUser = localUser else {
                        TCSLogErrorWithMark("invalid local user")
                        return .error("The local user \(username) could not be found")
                    }
                    TCSLogWithMark()

                    if shouldUpdatePassword==false {
                        TCSLogWithMark("shouldUpdatePassword set to false")
                        return .success(UsernamePasswordCredentials(username:nil,password: passwordEntered))
                    }
                    TCSLogWithMark()
                    guard let newPassword = newPassword else {
                        TCSLogWithMark("Password not provided for changing")
                        return .error("Password not provided for changing")

                    }
                    TCSLogWithMark()
                    do {
                        TCSLogWithMark("attempting to change password")
                        try localUser.changePassword(passwordEntered, toPassword: newPassword)
                    }
                    catch {
                        TCSLogErrorWithMark("Error setting local password to cloud password")

                        return .error("Error setting local password to cloud password: \(error.localizedDescription)")
                    }
                    isDone=true
                    window?.close()
                    TCSLogWithMark("returning success with local password")
                    return .success(UsernamePasswordCredentials(username:nil,password: passwordEntered))
                default:
                    window?.shake(self)

                }
            }
        }
    }

    
    override func windowDidLoad() {
        super.windowDidLoad()
        TCSLogWithMark()
    }
  

    @IBAction func removeKeychainButtonPressed(_ sender: Any) {


        //override or prefs has admin username / password so don't prompt
        if let aUsername = DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue), let aPassword =
            DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue), aUsername.isEmpty==false, aPassword.isEmpty==false {
            adminUsername = aUsername
            adminPassword = aPassword
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
        passwordEntered=passwordTextField.stringValue

        if self.window?.isModalPanel==true {
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
