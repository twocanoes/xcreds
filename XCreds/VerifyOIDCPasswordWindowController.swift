//
//  VerifyOIDCPassword.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/4/22.
//

import Cocoa

class VerifyOIDCPasswordWindowController: NSWindowController {

    @IBOutlet weak var passwordTextField: NSSecureTextField!

    var password:String?
    override func windowDidLoad() {
        super.windowDidLoad()

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
