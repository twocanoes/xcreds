//
//  LoginPasswordWindowController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//

import Cocoa

class LoginPasswordWindowController: NSWindowController {

    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var resetButton: NSButton!

    var password:String?
    var resetKeychain = false

    override func windowDidLoad() {
        super.windowDidLoad()

        if UserDefaults.standard.string(forKey: PrefKeys.localAdminCredentialScriptPath.rawValue) != nil{
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
            self.window?.close()
        }
    }
}
