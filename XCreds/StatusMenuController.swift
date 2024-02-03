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
        case SharesMenuItem=7
        case QuitMenuItem=8
        case Additional=9

    }
    enum MenuElements:String {
        case linkOrAppPath
        case menuItemName
        case separatorAfter
        case separatorBefore
    }
    struct StatusMenuItem {
        var name:String
        var path:String
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
    @IBOutlet var statusMenu:NSMenu!

    override func awakeFromNib() {
        if let menuItems = DefaultsOverride.standardOverride.value(forKey: PrefKeys.menuItems.rawValue) as? Array<Dictionary<String,Any?>> {
            let insertPos = 7
            var index = 0
            for item in menuItems {
                if let name = item[MenuElements.menuItemName.rawValue] as? String,
                   let path = item[MenuElements.linkOrAppPath.rawValue] as? String,
                    let separatorBefore = item[MenuElements.separatorBefore.rawValue] as? Bool,
                    let separatorAfter = item[MenuElements.separatorAfter.rawValue] as? Bool
                {
                    let menuItem = NSMenuItem(title: name, action:#selector(additionalMenuItemSelected(_:)) , keyEquivalent: "")
                    menuItem.target=self
                    menuItem.tag=9
                    menuItem.representedObject=StatusMenuItem(name: name, path: path)
                    if separatorBefore == true {
                        statusMenu.insertItem(NSMenuItem.separator(), at: insertPos+index)
                        index+=1
                    }
                    statusMenu.insertItem(menuItem, at:insertPos+index)
                    index+=1
                    if separatorAfter == true {
                        statusMenu.insertItem(NSMenuItem.separator(), at:insertPos+index)
                        index+=1
                    }

                }

            }
        }
    }
    @objc func additionalMenuItemSelected(_ sender:NSMenuItem){
        guard let menuItemInfo = sender.representedObject as? StatusMenuItem else  {
            return
        }

        let pathString = menuItemInfo.path

        if pathString.hasPrefix("http"), let url = URL(string: pathString){

            NSWorkspace.shared.open(url)

        }
        else  {
            let fileUrl = URL(fileURLWithPath: pathString)
            NSWorkspace.shared.openApplication(at: fileUrl, configuration: NSWorkspace.OpenConfiguration())
        }

    }
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
            else {
                quitMenuItem.isHidden=false
                quitMenuItemSeparator.isHidden=false
            }

        case .PasswordExpires:
            
            if let passwordExpires = mainController?.passwordExpires {
                menuItem.isHidden=false
                menuItem.title="Password Expires: \(passwordExpires)"
            }
            else {
                menuItem.isHidden=true
                
            }
            return false
        case .SharesMenuItem:
            return true
        case .Additional:
            return true
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
        mainController?.showSignInWindow(force: true)

    }
}



