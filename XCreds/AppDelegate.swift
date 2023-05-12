//
//  AppDelegate.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var loginPasswordWindow: NSWindow!
    @IBOutlet var window: NSWindow!
    var mainController:MainController?
    var wifiWindowController:WifiWindowController?
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let infoPlist = Bundle.main.infoDictionary

        if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"] {
            TCSLogWithMark("Build \(build)")

        }


        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenLocked(_:)), name:NSNotification.Name("com.apple.screenIsLocked") , object: nil)
//        ManagedPreferences.shared.preference(forKey: .clientID)
        mainController = MainController.init()
        mainController?.run()
        mainMenu.statusBarItem.menu = mainMenu.mainMenu

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    @objc func screenLocked(_ sender:Any) {
        if UserDefaults.standard.bool(forKey: PrefKeys.shouldSwitchToLoginWindowWhenLocked.rawValue)==true{
            TCSLoginWindowUtilities().switchToLoginWindow(self)
        }
    }


}

