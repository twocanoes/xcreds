//
//  PrefsMenuItem.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class PrefsMenuItem: NSMenuItem {

    override var title: String {
        get {
            "Preferences..."
        }
        set {
            return
        }
    }

    init() {
         super.init(title: "", action: #selector(doAction), keyEquivalent: "")
         self.target = self
     }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func doAction() {
        if mainMenu.prefsWindow == nil {
            mainMenu.prefsWindow = PreferencesWindowController()
        }
        mainMenu.prefsWindow?.window!.forceToFrontAndFocus(nil)
    }
}
