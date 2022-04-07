//
//  PreferencesWindowController.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class PreferencesWindowController: NSWindowController {

    @IBOutlet weak var clearTokenButton: NSButton!

    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("PreferencesWindow")
    }

    @IBAction func clearTokensClicked(_ sender: Any) {
        UserDefaults.standard.set(nil, forKey: PrefKeys.accessToken.rawValue)
        UserDefaults.standard.set(nil, forKey: PrefKeys.idToken.rawValue)
        UserDefaults.standard.set(nil, forKey: PrefKeys.refreshToken.rawValue)
    }

}
