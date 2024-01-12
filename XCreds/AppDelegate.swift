//
//  AppDelegate.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, DSQueryable {
   
    @IBOutlet weak var loginPasswordWindow: NSWindow!
    @IBOutlet var window: NSWindow!
    var mainController:MainController?
    var screenIsLocked=true
    var isDisplayAsleep=true
    var waitForScreenToWake=false
//    @IBOutlet var shareMounterMenu: ShareMounterMenu?
    @IBOutlet weak var statusMenu: NSMenu!
    var shareMenu:NSMenu?
    var statusBarItem:NSStatusItem?

    func updateStatusMenuIcon(showDot:Bool){


        DispatchQueue.main.async {

            TCSLogWithMark()
            if showDot==true {
                TCSLogWithMark("showing with dot")
                self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon check")

            }
            else {
                TCSLogWithMark("showing without dot")
                self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon")

            }
        }

    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.isVisible=true
        statusBarItem?.menu = statusMenu
        self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon")
//        shareMounterMenu = ShareMounterMenu()
//        shareMounterMenu?.updateShares()
//        shareMenu = shareMounterMenu?.buildMenu()

        let defaultsPath = Bundle.main.path(forResource: "defaults", ofType: "plist")

        if let defaultsPath = defaultsPath {

            let defaultsDict = NSDictionary(contentsOfFile: defaultsPath)
            TCSLogWithMark()
            DefaultsOverride.standardOverride.register(defaults: defaultsDict as! [String : Any])
        }


        let infoPlist = Bundle.main.infoDictionary

        if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"] {
            TCSLogWithMark("Build \(build)")

        }
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenLocked(_:)), name:NSNotification.Name("com.apple.screenIsLocked") , object: nil)

        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenUnlocked(_:)), name:NSNotification.Name("com.apple.screenIsUnlocked") , object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidSleep(_:)), name:NSWorkspace.screensDidSleepNotification , object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidWake(_:)), name:NSWorkspace.screensDidWakeNotification , object: nil)

        mainController = MainController()
        mainController?.setup()

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    @objc func screenUnlocked(_ sender:Any) {
        TCSLogWithMark()
        screenIsLocked=false

    }
    @objc func screenLocked(_ sender:Any) {
        TCSLogWithMark()
        screenIsLocked=true
        if isDisplayAsleep==true{

            waitForScreenToWake=true
        }
        else {
            waitForScreenToWake=false
            switchToLoginWindow()        }

    }
    @objc func screenDidSleep(_ sender:Any) {
        TCSLogWithMark()
        isDisplayAsleep=true
    }
    @objc func screenDidWake(_ sender:Any) {
        TCSLogWithMark()
        isDisplayAsleep=false

        if waitForScreenToWake==true {
            waitForScreenToWake=false
            switchToLoginWindow()
        }
    }
    func switchToLoginWindow()  {
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldSwitchToLoginWindowWhenLocked.rawValue)==true{
            TCSLoginWindowUtilities().switchToLoginWindow(self)
        }

    }


}

