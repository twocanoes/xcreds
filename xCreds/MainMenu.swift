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

    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // windows

    var webView: WebViewController?
    var prefsWindow: PreferencesWindowController?

    override init() {
        mainMenu = NSMenu()
        super.init()
        buildMenu()
        self.statusBarItem.menu = mainMenu
        self.statusBarItem.button?.title = "🔄"
        mainMenu.delegate = self

    }

    func buildMenu() {

        if menuOpen { return }

        menuBuilt = Date()
        mainMenu.removeAllItems()

        // add menu items

        mainMenu.addItem(SignInMenuItem())
        mainMenu.addItem(CheckTokenMenuItem())
        mainMenu.addItem(NSMenuItem.separator())
        mainMenu.addItem(PrefsMenuItem())

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
