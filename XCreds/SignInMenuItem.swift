//
//  SignInMenuItem.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class SignInMenuItem: NSMenuItem {

    override var title: String {
        get {
            if mainMenu.signedIn==true {
                return "Refresh..."
            }
            else {
                return "Sign In..."
            }

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

        if DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue) != nil && DefaultsOverride.standardOverride.value(forKey: PrefKeys.clientID.rawValue) != nil {
            if (mainMenu.webView==nil){
                mainMenu.webView = WebViewWindowController()
            }
            mainMenu.webView?.window!.forceToFrontAndFocus(nil)
            mainMenu.webView?.loadPage()
        }
        else {
            if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowPreferencesOnStart.rawValue)==true{
                PrefsMenuItem().doAction()
            }
        }
    }
}
