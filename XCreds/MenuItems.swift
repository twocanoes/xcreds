//
//  PrefsMenuItem.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class AboutMenuItem: NSMenuItem {

    override var title: String {
        get {
            "About XCreds"
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

        if mainMenu.aboutWindowController == nil {
            mainMenu.aboutWindowController = AboutWindowController()
        }
        mainMenu.aboutWindowController?.window!.forceToFrontAndFocus(nil)
        NSApp.activate(ignoringOtherApps: true)

        

    }
}
class ChangePasswordMenuItem: NSMenuItem {

    override var title: String {
        get {

            return "Change Password..."
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
        if let passwordChangeURLString = DefaultsOverride.standardOverride.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0, let url = URL(string: passwordChangeURLString) {


            NSWorkspace.shared.open(url)
        }
    }
}
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
                mainMenu.webView = WebViewController()
            }
//            mainMenu.webView?.window!.forceToFrontAndFocus(nil)
//            mainMenu.webView?.loadPage()
        }
        else {
            if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowPreferencesOnStart.rawValue)==true{
                PrefsMenuItem().doAction()
            }
        }
    }
}
class PrefsMenuItem: NSMenuItem {

    override var title: String {
        get {
            "Show Settings..."
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
class CheckTokenMenuItem: NSMenuItem {

    override var isHidden: Bool {
        get {
            if let _ = DefaultsOverride.standardOverride.object(forKey: PrefKeys.accessToken.rawValue) as? String {
                return false
            } else {
                return true
            }
        }
        set {
            return
        }
    }

    override var title: String {
        get {
            "Check Token"
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
    }
}
class StatusUpdateMenuItem: NSMenuItem {

    var internalTitle=""
    override var title: String {
        get {
           internalTitle
        }
        set {
            return

        }
    }

    init(title:String) {
         super.init(title: "", action: #selector(doAction), keyEquivalent: "")
        internalTitle=title
        self.isEnabled=false
     }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func doAction() {
//        if mainMenu.prefsWindow == nil {
//            mainMenu.prefsWindow = PreferencesWindowController()
//        }
//        mainMenu.prefsWindow?.window!.forceToFrontAndFocus(nil)
    }
}
