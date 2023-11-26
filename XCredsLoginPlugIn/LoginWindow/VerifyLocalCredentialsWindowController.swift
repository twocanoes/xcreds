//
//  VerifyLocalCredentialsWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 11/25/23.
//

import Cocoa

class VerifyLocalCredentialsWindowController: NSWindowController {

    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    override func windowDidLoad() {
        super.windowDidLoad()

    }
    
    @IBAction func okButtonPressed(_ sender: Any) {
    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
    }
}
