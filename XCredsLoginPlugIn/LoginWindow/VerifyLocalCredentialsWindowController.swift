//
//  VerifyLocalCredentialsWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 11/25/23.
//

import Cocoa

class VerifyLocalCredentialsWindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak private var usernameTextField: NSTextField!
    @IBOutlet weak private var passwordTextField: NSSecureTextField!
    @IBOutlet weak private var createNewAccountButton: NSButton!

    var username:String?
    var password:String?
    var shouldCreateNewAccount:Bool?=false

    override func windowDidLoad() {
        super.windowDidLoad()

    }
    func windowDidBecomeKey(_ notification: Notification) {
        if let shouldCreateNewAccount = shouldCreateNewAccount{
            createNewAccountButton.isHidden = !shouldCreateNewAccount
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
