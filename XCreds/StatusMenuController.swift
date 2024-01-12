//
//  MainMenu.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa


class StatusMenuController: NSObject, NSMenuItemValidation {
    enum StatusMenuItemType:Int {
        case AboutMenuItem=1
        case NextPasswordCheckMenuItem=2
        case CredentialStatusMenuItem=3
        case PasswordExpires=4
        case SignInMenuItem=5
        case ChangePasswordMenuItem=6
        case QuitMenuItem=7

    }
    var signedIn = false
    var aboutWindowController: AboutWindowController?

//    var mainController:MainController? {
//
//        let appDelegate = NSApp.delegate as? AppDelegate
//        return appDelegate?.mainController
//
//
//    }
    @IBOutlet var signinMenuItem:NSMenuItem!
    @IBOutlet var changePasswordMenuItem:NSMenuItem!
    @IBOutlet var quitMenuItem:NSMenuItem!
    @IBOutlet var quitMenuItemSeparator:NSMenuItem!

    @IBOutlet var aboutMenuItem:NSMenuItem!
    @IBOutlet var aboutMenuItemSeparator:NSMenuItem!
    @IBOutlet var nextPasswordCheckMenuItem:NSMenuItem!
    @IBOutlet var credentialStatusMenuItem:NSMenuItem!



    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let appDelegate = NSApp.delegate as? AppDelegate
        let mainController = appDelegate?.mainController

        let tag = menuItem.tag

        guard let menuType = StatusMenuItemType(rawValue: tag) else {
            return false
        }

        switch menuType {

        case .AboutMenuItem:

            if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowAboutMenu.rawValue) == false {

                aboutMenuItem.isHidden=true
                aboutMenuItemSeparator.isHidden=true
                return false
            }
            aboutMenuItem.isHidden=false
            aboutMenuItemSeparator.isHidden=false

            let infoPlist = Bundle.main.infoDictionary

            if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"], let appVersion =  infoPlist["CFBundleShortVersionString"]{
                menuItem.title="About XCreds \(appVersion) (\(build))"

            }

        case .NextPasswordCheckMenuItem:
            print("NextPasswordCheckMenuItem")
            if let nextPassCheck = mainController?.nextPasswordCheck {
                menuItem.title="Next check: \(nextPassCheck)"
            }
            return false
        case .CredentialStatusMenuItem:
            print("CredentialStatusMenuItem")
            if let status = mainController?.credentialStatus {
                menuItem.title="Credentials Status: \(status)"
            }
            return false

        case .SignInMenuItem:
            print("SignInMenuItem")
            

        case .ChangePasswordMenuItem:

            print("ChangePasswordMenuItem")

            if let passwordChangeURLString = DefaultsOverride.standardOverride.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0, let _ = URL(string: passwordChangeURLString) {

                menuItem.isHidden=false
                return true
            }
            else  {
                menuItem.isHidden=true
                return false
            }

        case .QuitMenuItem:
            if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowQuitMenu.rawValue)==false{
                quitMenuItem.isHidden=true
                quitMenuItemSeparator.isHidden=true

            }
            quitMenuItem.isHidden=false
            quitMenuItemSeparator.isHidden=false

        case .PasswordExpires:

            if let passwordExpires = mainController?.passwordExpires {
                menuItem.isHidden=false
                menuItem.title="Password Expires: \(passwordExpires)"
            }
            else {
                menuItem.isHidden=true

            }
            return false
        }
        return true
    }

    // windows

//    var webViewController: WebViewController?
//    var prefsWindow: PreferencesWindowController?
//    var signInMenuItem:SignInMenuItem
//    override init() {
////        mainMenu = NSMenu()
////        signInMenuItem = SignInMenuItem()
//
//        super.init()
////        buildMenu()
//        windowController = DesktopLoginWindowController(windowNibName: "DesktopLoginWindowController")
////        self.statusBarItem.menu = mainMenu
////        self.statusBarItem.button?.image=NSImage(named: "xcreds menu icon")
////        mainMenu.delegate = self
////        NotificationCenter.default.addObserver(forName: Notification.Name("CheckTokenStatus"), object: nil, queue: nil) { notification in
////            if let userInfo=notification.userInfo, let nextUpdate = userInfo["NextCheckTime"] as? Date{
////                let dateFormatter = DateFormatter()
////                dateFormatter.timeStyle = .short
////                let updateDateString = dateFormatter.string(from: nextUpdate)
//////                self.updateStatus="Next password check: \(updateDateString)"
////            }
////        }
//    }

    @IBAction func aboutMenuItemSelected(_ sender:Any?){
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.window!.forceToFrontAndFocus(nil)
        NSApp.activate(ignoringOtherApps: true)



    }

    @IBAction func changePasswordMenuItemSelected(_ sender:Any?)  {
        if let passwordChangeURLString = DefaultsOverride.standardOverride.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0, let url = URL(string: passwordChangeURLString) {


            NSWorkspace.shared.open(url)
        }
    }
    @IBAction func quitMenuItemSelected(_ sender:Any?)  {

        NSApp.terminate(self)

    }
    @IBAction func nextPasswordCheckTimeMenuItemSelected(_ sender:Any?)  {

    }
    @IBAction func credentialStatusMenuItemSelected(_ sender:Any?)  {

    }
    @IBAction func signInMenuItemSelected(_ sender:Any?)  {
        let appDelegate = NSApp.delegate as? AppDelegate

        let mainController = appDelegate?.mainController
        mainController?.showSignInWindow()

    }
//    func buildMenu() {
//
//        var firstItemShown = false
//        if menuOpen { return }
//
//        menuBuilt = Date()
//        mainMenu.removeAllItems()
//        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowAboutMenu.rawValue)==true{
//
//
//            mainMenu.addItem(AboutMenuItem())
//            mainMenu.addItem(NSMenuItem.separator())
//            firstItemShown = true
//        }
//        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowTokenUpdateStatus.rawValue)==true{
//
//            mainMenu.addItem(StatusUpdateMenuItem(title: self.updateStatus))
//            mainMenu.addItem(NSMenuItem.separator())
//
//            firstItemShown = true
//        }
//
//        if (self.passwordExpires != ""){
//            mainMenu.addItem(StatusUpdateMenuItem(title: self.passwordExpires))
//            mainMenu.addItem(NSMenuItem.separator())
//            firstItemShown = true
//
//        }
//
//        if let passwordChangeURLString = DefaultsOverride.standardOverride.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0 {
//            if firstItemShown == false {
//                mainMenu.addItem(NSMenuItem.separator())
//                firstItemShown = true
//
//            }
//            mainMenu.addItem(ChangePasswordMenuItem())
//            mainMenu.addItem(NSMenuItem.separator())
//
//        }
//
//        mainMenu.addItem(signInMenuItem)
//        mainMenu.addItem(CheckTokenMenuItem())
//        //        mainMenu.addItem(PrefsMenuItem())
//        TCSLogWithMark()
//        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowQuitMenu.rawValue)==true{
//            let quitMenuItem = NSMenuItem(title: "Quit", action:#selector(NSApp.terminate(_:)), keyEquivalent: "")
//
//            mainMenu.addItem(NSMenuItem.separator())
//            mainMenu.addItem(quitMenuItem)
//        }

//        if signedIn == true {
//            statusBarItem.button?.image=NSImage(named: "xcreds menu icon check")
//
//        }
//        else {
//            statusBarItem.button?.image=NSImage(named: "xcreds menu icon")
//        }
    }

    //MARK: NSMenuDelegate
    /*


     */
func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

  return true
}

    func menuWillOpen(_ menu: NSMenu) {

    }
//
    func menuDidClose(_ menu: NSMenu) {
//        menuOpen = false
//        RunLoop.main.perform {
//            self.buildMenu()
//        }
    }

//    @objc fileprivate func buildMenuThrottle() {
//
//        // don't rebuild the menu if it's been built in the last 3 seconds
//        // otherwise we can get into a loop
//        if (menuBuilt?.timeIntervalSinceNow ?? 0 ) < -3 {
//            buildMenu()
//        }
//    }
//}
