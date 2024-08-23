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
    @IBOutlet var shareMounterMenu: ShareMounterMenu?
    @IBOutlet weak var statusMenu: NSMenu!
    var shareMenu:NSMenu?
    var statusBarItem:NSStatusItem?

    func updateShareMenu(adUser:ADUserRecord){
        shareMounterMenu?.shareMounter?.adUserRecord = adUser
        shareMounterMenu?.updateShares(connected: true)
        shareMenu = shareMounterMenu?.buildMenu(connected: true)

        if let sharesMenuItem = statusMenu.item(withTag: StatusMenuController.StatusMenuItemType.SharesMenuItem.rawValue) {

            if shareMenu?.items.count==0{
                sharesMenuItem.isHidden=true
            }
            else {
                sharesMenuItem.isHidden=false
                statusMenu.setSubmenu(shareMenu, for:sharesMenuItem )
            }

        }

    }
    func updateStatusMenuExpiration(_ expires:Date?) {

        ///TODO: implement edge cases
        return
//        DispatchQueue.main.async {
//
//            TCSLogWithMark()
//
//            if let expires = expires {
//                let daysToGo = Int(abs(expires.timeIntervalSinceNow)/86400)
//
//                self.statusBarItem?.button?.title="\(daysToGo)d"
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateStyle = .medium
//                dateFormatter.timeStyle = .short
//
//
//                self.statusBarItem?.button?.toolTip = dateFormatter.string(from: expires as Date)
//
//            }
//            else {
//                self.statusBarItem?.button?.title=""
//                self.statusBarItem?.button?.toolTip = ""
//            }
//
//
//        }
    }
    func updateStatusMenuIcon(showDot:Bool){


        DispatchQueue.main.async {

            TCSLogWithMark()
            if showDot==true {
                TCSLogWithMark("showing with dot")

                if let iconData=DefaultsOverride.standardOverride.data(forKey: PrefKeys.menuItemIconCheckedData.rawValue), let image = NSImage(data: iconData) {
                    image.size=NSMakeSize(16, 16)
                    self.statusBarItem?.button?.image=image

                }
                else {
                    self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon check")
                }

            }
            else {
                TCSLogWithMark("showing without dot")
                if let iconData=DefaultsOverride.standardOverride.data(forKey: PrefKeys.menuItemIconData.rawValue), let image = NSImage(data: iconData) {
                    image.size=NSMakeSize(16, 16)

                    self.statusBarItem?.button?.image=image

                }
                else {
                    self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon")
                }

            }

        }

    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NetworkMonitor.shared.startMonitoring()
        updatePrefsFromDS()
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.isVisible=true
        statusBarItem?.menu = statusMenu

        
        if let iconData=DefaultsOverride.standardOverride.data(forKey: PrefKeys.menuItemIconData.rawValue), let image = NSImage(data: iconData) {
            image.size=NSMakeSize(16, 16)

            self.statusBarItem?.button?.image=image
        }
        else {
            self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon")
        }
        let shareMounter = ShareMounter()

        shareMounterMenu = ShareMounterMenu()
        shareMounterMenu?.shareMounter = shareMounter
        shareMounterMenu?.updateShares(connected: true)
        shareMenu = shareMounterMenu?.buildMenu(connected: true)

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

        if var autofillAppPath = Bundle.main.path(forResource: "XCreds Login Autofill", ofType: "app"){
            autofillAppPath = autofillAppPath + "/Contents/MacOS/XCreds Login Autofill"
            if FileManager.default.fileExists(atPath: autofillAppPath){

                let msg = TCTaskHelper.shared().runCommand(autofillAppPath, withOptions:["-r"] )

                print(msg)
            }
        }
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

    func updatePrefsFromDS(){
        if let currentUser = PasswordUtils.getCurrentConsoleUserRecord() {

            do {
                let attributesArray = try currentUser.recordDetails(forAttributes: nil)
                for currAttribute in attributesArray {
                    if let key = currAttribute.key as? String, key.hasPrefix("dsAttrTypeNative:_xcreds"), let value = currAttribute.value as? Array<String>, let lastValue = value.last {
                        let components = key.components(separatedBy: ":")
                        if let strippedKey = components.last{
                            UserDefaults.standard.set(lastValue, forKey:strippedKey)
                        }
                    }
                }
            }
            catch {
                TCSLogWithMark("could not get attributes from user")
            }
        }

    }
}

