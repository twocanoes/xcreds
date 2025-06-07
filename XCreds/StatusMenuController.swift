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
        case OIDCUsername=2
        case KerberosUsername=3
        case NextADPasswordCheckMenuItem=4
        case NextTokenPasswordCheckMenuItem=5
        case ADCredentialStatusMenuItem=6
        case CloudPasswordExpires=7
        case ADPasswordExpires=8
        case SignInMenuItem=9
        case ChangePasswordMenuItem=10
        case SharesMenuItem=11
        case QuitMenuItem=12
        case Additional=13
        case SetupCardMenuItem=14
        case OIDCCredentialStatusMenuItem=15

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
    var oidcUsername = ""
    var kerberosPrincipalName = ""
    @IBOutlet var signinMenuItem:NSMenuItem!
    @IBOutlet var changePasswordMenuItem:NSMenuItem!
    @IBOutlet var quitMenuItem:NSMenuItem!
    @IBOutlet var quitMenuItemSeparator:NSMenuItem!
    
    @IBOutlet var aboutMenuItem:NSMenuItem!
    @IBOutlet var aboutMenuItemSeparator:NSMenuItem!
    @IBOutlet var nextPasswordCheckMenuItem:NSMenuItem!
    @IBOutlet var credentialStatusMenuItem:NSMenuItem!
    @IBOutlet var statusMenu:NSMenu!
    @IBOutlet var sharesMenuItem:NSMenuItem!
    override func awakeFromNib() {

        let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
        if let userNames = try? currentUser?.values(forAttribute: "dsAttrTypeNative:_xcreds_oidc_username") as? [String], userNames.count>0, let username = userNames.first {
            oidcUsername = username

        }
        else if let oidcUsernamePrefs = UserDefaults.standard.string(forKey:"_xcreds_oidc_username" )
        {
            oidcUsername = oidcUsernamePrefs
        }
        if let userNames = try? currentUser?.values(forAttribute: "dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal") as? [String], userNames.count>0, let username = userNames.first {
            kerberosPrincipalName = username

        }


        if let menuItems = DefaultsOverride.standardOverride.value(forKey: PrefKeys.menuItems.rawValue) as? Array<Dictionary<String,Any?>> {
            let insertPos = StatusMenuItemType.OIDCCredentialStatusMenuItem.rawValue+1
            var index = 0
            for item in menuItems {
                if let name = item[MenuElements.menuItemName.rawValue] as? String,
                   let path = item[MenuElements.linkOrAppPath.rawValue] as? String,
                    let separatorBefore = item[MenuElements.separatorBefore.rawValue] as? Bool,
                    let separatorAfter = item[MenuElements.separatorAfter.rawValue] as? Bool
                {
                    let menuItem = NSMenuItem(title: name, action:#selector(additionalMenuItemSelected(_:)) , keyEquivalent: "")
                    menuItem.target=self
                    menuItem.tag=StatusMenuItemType.Additional.rawValue
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

        if pathString.hasPrefix("http") || pathString.hasPrefix("mailto"), let url = URL(string: pathString){

            NSWorkspace.shared.open(url)

        }
        else  {
            let fileUrl = URL(fileURLWithPath: pathString)
            NSWorkspace.shared.openApplication(at: fileUrl, configuration: NSWorkspace.OpenConfiguration())
        }

    }
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

        var adSetup = false
        var oidcSetup = false

        if let adDomainFromPrefs = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aDDomain.rawValue){

            if adDomainFromPrefs.isEmpty==false, adDomainFromPrefs.count>0 {
                adSetup=true

            }
        }
        if let oidcDiscoveryFromPrefs = DefaultsOverride.standardOverride.string(forKey: PrefKeys.discoveryURL.rawValue){

            if oidcDiscoveryFromPrefs.isEmpty==false, oidcDiscoveryFromPrefs.count>0 {
                oidcSetup=true

            }
        }
        let appDelegate = NSApp.delegate as? AppDelegate
        let mainController = appDelegate?.mainController
        
        let tag = menuItem.tag
        guard let menuType = StatusMenuItemType(rawValue: tag) else {
            return false
        }
        
        switch menuType {

        case .SetupCardMenuItem:
            return true

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
            
        case .NextADPasswordCheckMenuItem:
            menuItem.isHidden=false
            if adSetup==false {
                menuItem.isHidden=true
                return false

            }
            if let nextADPassCheck = mainController?.nextPasswordADCheck {
                menuItem.title="Next AD Check: \(nextADPassCheck)"
            }

            
            return false

        case .NextTokenPasswordCheckMenuItem:
            menuItem.isHidden=false
            if oidcSetup==false {
                menuItem.isHidden=true
                return false

            }
            if let nextTokenPassCheck = mainController?.nextPasswordTokenCheck {
                menuItem.title="Next OIDC Check: \(nextTokenPassCheck)"
            }
            return false

        case .ADCredentialStatusMenuItem:
            menuItem.isHidden=false
            if adSetup==false {
                menuItem.isHidden=true
                return false

            }

            if let status = mainController?.kerberosCredentialStatus {
                menuItem.title="Active Directory Credentials Status: \(status)"
            }
            return false


        case .OIDCCredentialStatusMenuItem:
            menuItem.isHidden=false
            if oidcSetup==false {
                menuItem.isHidden=true
                return false

            }


            if let status = mainController?.tokenCredentialStatus {
                menuItem.title="Credentials Status: \(status)"
            }
            return false

        case .SignInMenuItem:
            print("SignInMenuItem")
            if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowSignInMenuItem.rawValue) == false {
                
                signinMenuItem.isHidden=true
                return false
            }
            signinMenuItem.isHidden=false
            
            
            
            
        case .ChangePasswordMenuItem:
            
            print("ChangePasswordMenuItem")
            
            if let passwordChangeURLString = DefaultsOverride.standardOverride.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0 {
                
                menuItem.isHidden=false
                return true
            }
            else if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseADNativePasswordChangeMenuItem.rawValue) == true {
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
            
        case .CloudPasswordExpires:
            menuItem.isHidden=false
            if oidcSetup==false {
                menuItem.isHidden=true
                return false

            }

            if let passwordExpires = mainController?.cloudPasswordExpires {
                menuItem.isHidden=false
                menuItem.title="OIDC Password Expires: \(passwordExpires)"
            }
            else {
                menuItem.isHidden=true
            }
            return false
            
        case .ADPasswordExpires:
            menuItem.isHidden=false
            if adSetup==false {
                menuItem.isHidden=true
                return false

            }

            if let passwordExpires = mainController?.adPasswordExpires, DefaultsOverride.standardOverride.bool(forKey: PrefKeys.hideExpiration.rawValue)==false {
                TCSLogWithMark("Unhiding password expires")
                menuItem.isHidden=false
                menuItem.title="AD Password Expires: \(passwordExpires)"
            }
            else {
                TCSLogWithMark("hiding password expires")
                menuItem.isHidden=true
            }
            return false
        case .SharesMenuItem:
            menuItem.isHidden=false
            if adSetup==false {
                menuItem.isHidden=true
                return false

            }

            if let shareMenuItemTitle = DefaultsOverride.standardOverride.value(forKey: PrefKeys.shareMenuItemName.rawValue) as? String {
                menuItem.title = shareMenuItemTitle
            }
            return true
        case .Additional:
            return true
        case .OIDCUsername:
            menuItem.isHidden=false
            if oidcSetup==false {
                menuItem.isHidden=true
                return false

            }

            var userName = "None"
            if oidcUsername.isEmpty == false {
                menuItem.isHidden=false
                userName = oidcUsername
                menuItem.title = "OIDC Username: \(userName) "

            }
            else {
                menuItem.isHidden=true
            }

            return false

        case .KerberosUsername:
            menuItem.isHidden=false
            if adSetup==false {
                menuItem.isHidden=true
                return false

            }

            var userName = "None"
            if kerberosPrincipalName.isEmpty == false {
                menuItem.isHidden=false
                userName = kerberosPrincipalName
                menuItem.title = "Active Directory Username: \(userName) "

            }
            else {
                menuItem.isHidden=true
            }
            //grayed out
            return false
        }


        return true
    }
    
    @IBAction func aboutMenuItemSelected(_ sender:Any?){
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.window!.forceToFrontAndFocus(nil)
        NSApp.activate(ignoringOtherApps: true)

    }
    
    @IBAction func changePasswordMenuItemSelected(_ sender:Any?)  {
        if  DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseADNativePasswordChangeMenuItem.rawValue)==true {
            let appDelegate = NSApp.delegate as? AppDelegate

            if let mainController = appDelegate?.mainController,
            let signInViewController = mainController.signInViewController{

                do {
                    try signInViewController.showResetUI()
                    TCSLogWithMark("reset password")
                }
                catch SignInViewController.SignInViewControllerResetPasswordError.cancelled  {
                    TCSLogWithMark("user cancelled")
                }
                catch {
                    NSAlert.showAlert(title: "Error resetting password", message: "There was an error resetting your password. \(error)")
                }
            }
        }
        else if let passwordChangeURLString = DefaultsOverride.standardOverride.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0 {

            if let url = URL(string: passwordChangeURLString) {
                NSWorkspace.shared.open(url)
            }
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



