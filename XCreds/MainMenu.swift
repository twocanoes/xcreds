//
//  MainMenu.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

// needs to be a singleton so it doesn't get reaped
let sharedMainMenu = MainMenu()

class ViewController: NSViewController {
    var myName: String = "ViewController"

    override func loadView() {
        view = NSView()
    }
}

class MainMenu: NSObject, NSMenuDelegate {

    var mainMenu: NSMenu
    var menuOpen = false // is the menu open?
    var menuBuilt: Date? // last time menu was built
    var updateStatus = "Starting Up..."
    var passwordExpires = ""
    var signedIn = false
    var mainWindow:NSWindow!
    var windowController: DesktopLoginWindowController!

    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // windows

    var webViewController: WebViewController?
    var prefsWindow: PreferencesWindowController?
    var aboutWindowController: AboutWindowController?
    override init() {
        mainMenu = NSMenu()
        super.init()
        buildMenu()
        windowController = DesktopLoginWindowController(windowNibName: "DesktopLoginWindowController")
//        print(windowController)
        self.statusBarItem.menu = mainMenu
        self.statusBarItem.button?.image=NSImage(named: "xcreds menu icon")
        mainMenu.delegate = self
        NotificationCenter.default.addObserver(forName: Notification.Name("CheckTokenStatus"), object: nil, queue: nil) { notification in
            if let userInfo=notification.userInfo, let nextUpdate = userInfo["NextCheckTime"] as? Date{
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .short
                let updateDateString = dateFormatter.string(from: nextUpdate)
                self.updateStatus="Next password check: \(updateDateString)"
            }
        }
    }

    func buildMenu() {

        var firstItemShown = false
        if menuOpen { return }

        menuBuilt = Date()
        mainMenu.removeAllItems()
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowAboutMenu.rawValue)==true{


            mainMenu.addItem(AboutMenuItem())
            mainMenu.addItem(NSMenuItem.separator())
            firstItemShown = true
        }
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowTokenUpdateStatus.rawValue)==true{

            mainMenu.addItem(StatusUpdateMenuItem(title: self.updateStatus))
            mainMenu.addItem(NSMenuItem.separator())

            firstItemShown = true
        }

        if (self.passwordExpires != ""){
            mainMenu.addItem(StatusUpdateMenuItem(title: self.passwordExpires))
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
    /*


     */
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
