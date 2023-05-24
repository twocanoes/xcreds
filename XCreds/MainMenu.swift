//
//  MainMenu.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa
//import SwiftUI

// needs to be a singleton so it doesn't get reaped
let mainMenu = MainMenu()

class MainMenu: NSObject, NSMenuDelegate {

    var mainMenu: NSMenu
    var menuOpen = false // is the menu open?
    var menuBuilt: Date? // last time menu was built

    var signedIn = false
    
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // windows

    var webView: WebViewWindowController?
    var prefsWindow: PreferencesWindowController?

    override init() {
        mainMenu = NSMenu()
        super.init()
        buildMenu()
        self.statusBarItem.menu = mainMenu
        self.statusBarItem.button?.image=NSImage(named: "xcreds menu icon")
        mainMenu.delegate = self

    }

    func buildMenu() {

        var firstItemShown = false
        if menuOpen { return }

        menuBuilt = Date()
        mainMenu.removeAllItems()

        // add menu items
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowAboutMenu.rawValue)==true{
            mainMenu.addItem(AboutMenuItem())
            mainMenu.addItem(NSMenuItem.separator())
            firstItemShown = true
        }
        if let passwordChangeURLString = DefaultsOverride.standardOverride.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0 {
            if firstItemShown == false {
                mainMenu.addItem(NSMenuItem.separator())
                firstItemShown = true

            }
            mainMenu.addItem(ChangePasswordMenuItem())
            mainMenu.addItem(NSMenuItem.separator())

        }
        mainMenu.addItem(SignInMenuItem())
        mainMenu.addItem(CheckTokenMenuItem())
//        mainMenu.addItem(PrefsMenuItem())
        TCSLogWithMark()
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowQuitMenu.rawValue)==true{
            let quitMenuItem = NSMenuItem(title: "Quit", action:#selector(NSApp.terminate(_:)), keyEquivalent: "")

            mainMenu.addItem(NSMenuItem.separator())
            mainMenu.addItem(quitMenuItem)
        }

        if signedIn == true {
            statusBarItem.button?.image=NSImage(named: "xcreds menu icon check")

        }
        else {
            statusBarItem.button?.image=NSImage(named: "xcreds menu icon")
        }
    }

    //MARK: NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        menuOpen = true
    }

    func menuDidClose(_ menu: NSMenu) {
        menuOpen = false
        RunLoop.main.perform {
            self.buildMenu()
        }
    }

    @objc fileprivate func buildMenuThrottle() {

        // don't rebuild the menu if it's been built in the last 3 seconds
        // otherwise we can get into a loop
        if (menuBuilt?.timeIntervalSinceNow ?? 0 ) < -3 {
            buildMenu()
        }
    }
}
