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

        if sharedMainMenu.aboutWindowController == nil {
            sharedMainMenu.aboutWindowController = AboutWindowController()
        }
        sharedMainMenu.aboutWindowController?.window!.forceToFrontAndFocus(nil)
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

    var signInViewController:SignInViewController?
    override var title: String {
        get {
            if sharedMainMenu.signedIn==true {
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
         super.init(title: "", action: #selector(showSigninWindow), keyEquivalent: "")
         self.target = self
     }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func showSigninWindow() {

        ScheduleManager.shared.setNextCheckTime()
        if DefaultsOverride.standardOverride.value(forKey: PrefKeys.shouldVerifyPasswordWithRopg.rawValue) != nil {

            if let window = sharedMainMenu.windowController.window{
                let bundle = Bundle.findBundleWithName(name: "XCreds")
                if let bundle = bundle{
                    TCSLogWithMark("Creating signInViewController")
                    signInViewController = SignInViewController(nibName: "LocalUsersViewController", bundle:bundle)

                    guard let signInViewController = signInViewController else {
                        return
                    }
                    
                    if let contentView = window.contentView {

                        signInViewController.view.wantsLayer=true
                        window.contentView?.addSubview(signInViewController.view)
                        var x = NSMidX(contentView.frame)
                        var y = NSMidY(contentView.frame)

                        x = x - signInViewController.view.frame.size.width/2
                        y = y - signInViewController.view.frame.size.height/2
                        let lowerLeftCorner = NSPoint(x: x, y: y)
                        signInViewController.localOnlyCheckBox.isHidden = true
                        signInViewController.localOnlyView.isHidden = true

                        signInViewController.view.setFrameOrigin(lowerLeftCorner)
                    }

                    window.makeKeyAndOrderFront(self)

                }
            }
        }
        else if DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue) != nil && DefaultsOverride.standardOverride.value(forKey: PrefKeys.clientID.rawValue) != nil {

            sharedMainMenu.windowController.window!.makeKeyAndOrderFront(self)
            sharedMainMenu.windowController.webViewController?.loadPage()
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
        if sharedMainMenu.prefsWindow == nil {
            sharedMainMenu.prefsWindow = PreferencesWindowController()
        }
        sharedMainMenu.prefsWindow?.window!.forceToFrontAndFocus(nil)
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
