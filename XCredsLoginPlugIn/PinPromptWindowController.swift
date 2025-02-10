//
//  PinPromptWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 12/6/24.
//

import Cocoa

class PinPromptWindowController: NSWindowController {
    @IBOutlet weak var pinTextField: NSSecureTextField!
    var pin:String?
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.canBecomeVisibleWithoutLogin=true
    }
    
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        NSApp.stopModal(withCode: .cancel)
    }
    @IBAction func okButtonPressed(_ sender: NSButton) {
        if !pinTextField.stringValue.isEmpty {
            pin = pinTextField.stringValue
            NSApp.stopModal(withCode: .OK)
        }
    }
}
