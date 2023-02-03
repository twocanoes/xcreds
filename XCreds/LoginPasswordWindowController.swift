//
//  LoginPasswordWindowController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//

import Cocoa

class LoginPasswordWindowController: NSWindowController {

    @IBOutlet weak var passwordTextField: NSSecureTextField!

    var password:String?
    var resetKeychain = false
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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
