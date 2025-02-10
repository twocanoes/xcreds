//
//  PinPromptWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 12/6/24.
//

import Cocoa

class PinSetWindowController: NSWindowController {
    @IBOutlet weak var pinTextField: NSSecureTextField!
    @IBOutlet weak var verifyPinTextField: NSSecureTextField!

    var pin:String?
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.canBecomeVisibleWithoutLogin=true
    }
    
    @IBAction func skipPINButtonPressed(_ sender: NSButton) {
        pin=nil
        NSApp.stopModal(withCode: .alertThirdButtonReturn)

    }
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        NSApp.stopModal(withCode: .cancel)
    }
    @IBAction func okButtonPressed(_ sender: NSButton) {
        if !pinTextField.stringValue.isEmpty,
           !verifyPinTextField.stringValue.isEmpty,
           pinTextField.stringValue == verifyPinTextField.stringValue

        {
            pin = pinTextField.stringValue
            NSApp.stopModal(withCode: .OK)
        }
        else {
            self.window?.shakeWindow()
        }
    }
}
