//
//  WebView.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa
import WebKit
import OIDCLite
import OpenDirectory

class LoginWebViewWindowController: WebViewWindowController {

    let uiLog = "uiLog"
    var internalDelegate:XCredsMechanismProtocol?
    var delegate:XCredsMechanismProtocol? {
        set {
            TCSLogWithMark()
            internalDelegate=newValue
            controlsViewController?.delegate = newValue
        }
        get {
            return internalDelegate
        }
    }
    var resolutionObserver:Any?
    var networkChangeObserver:Any?
    var loginProgressWindowController:LoginProgressWindowController?
    @IBOutlet weak var backgroundImageView: NSImageView!
    @IBOutlet var controlsViewController: ControlsViewController?

    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("LoginWebViewController")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        TCSLogWithMark()
        let allBundles = Bundle.allBundles
        for currentBundle in allBundles {
            TCSLogWithMark(currentBundle.bundlePath)
            if currentBundle.bundlePath.contains("XCreds") {
                controlsViewController = ControlsViewController.init(nibName: NSNib.Name("ControlsViewController"), bundle: currentBundle)
                if let controlsViewController = controlsViewController {
                    self.window?.contentView?.addSubview(controlsViewController.view)
                    let rect = NSMakeRect(0, 0, controlsViewController.view.frame.size.width,120)

                    controlsViewController.view.frame=rect

                }
                else {
                    TCSLogWithMark("controlsViewController nil")
                }
            }
        }

        resolutionObserver = NotificationCenter.default.addObserver(forName:NSApplication.didChangeScreenParametersNotification, object: nil, queue: nil) { notification in
            TCSLogWithMark("Resolution changed. Resetting size")
            self.setupLoginWindowAppearance()
        }

        TCSLogWithMark("loading webview for login")
        setupLoginWindowAppearance()
        TCSLogWithMark("loading page")
        loadPage()
    }

    func setupLoginWindowAppearance() {
        DispatchQueue.main.async {

            NSApp.activate(ignoringOtherApps: true)

            TCSLogWithMark("setting up window...")

            self.window?.level = .normal
            self.window?.orderFrontRegardless()
            self.window?.makeKeyAndOrderFront(self)

            self.window?.backgroundColor = NSColor.blue

            self.window?.titlebarAppearsTransparent = true
            
            self.window?.isMovable = false
            self.window?.canBecomeVisibleWithoutLogin = true

            let screenRect = NSScreen.screens[0].frame
            let screenWidth = screenRect.width
            let screenHeight = screenRect.height
            var loginWindowWidth = screenWidth //start with full size
            var loginWindowHeight = screenHeight //start with full size

            //if prefs define smaller, then resize window
            TCSLogWithMark("checking for custom height and width")
            if DefaultsOverride.standardOverride.object(forKey: PrefKeys.loginWindowWidth.rawValue) != nil  {
                let val = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowWidth.rawValue))
                if val > 100 {
                    TCSLogWithMark("setting loginWindowWidth to \(val)")
                    loginWindowWidth = val
                }
            }
            if DefaultsOverride.standardOverride.object(forKey: PrefKeys.loginWindowHeight.rawValue) != nil {
                let val = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowHeight.rawValue))
                if val > 100 {
                    TCSLogWithMark("setting loginWindowHeight to \(val)")
                    loginWindowHeight = val
                }
            }

            self.window?.setFrame(screenRect, display: true, animate: false)
            let rect = NSMakeRect(0, 0, self.window?.contentView?.frame.size.width ?? 100,120)

            self.controlsViewController?.view.frame=rect

            let backgroundImage = DefaultsHelper.backgroundImage()
            TCSLogWithMark()
            if let backgroundImage = backgroundImage {
                backgroundImage.size=screenRect.size
                self.backgroundImageView.image=backgroundImage
                self.backgroundImageView.imageScaling = .scaleProportionallyUpOrDown

                self.backgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)

            }
            TCSLogWithMark()
            self.webView.frame=NSMakeRect((screenWidth-CGFloat(loginWindowWidth))/2,(screenHeight-CGFloat(loginWindowHeight))/2, CGFloat(loginWindowWidth), CGFloat(loginWindowHeight))
            TCSLogWithMark()
        }
//            self.window?.setFrame(NSMakeRect((screenWidth-CGFloat(width))/2,(screenHeight-CGFloat(height))/2, CGFloat(width), CGFloat(height)), display: true, animate: false)
//        }
//
    }

//    @objc override var windowNibName: NSNib.Name {
//        return NSNib.Name("LoginWebView")
//    }
    func loginTransition() {
        TCSLogWithMark()
//        let screenRect = NSScreen.screens[0].frame
//        let progressIndicator=NSProgressIndicator.init(frame: NSMakeRect(screenRect.width/2-16  , 3*screenRect.height/4-16,32, 32))
//        progressIndicator.style = .spinning
//        progressIndicator.startAnimation(self)
//        webView.addSubview(progressIndicator)
//
//        if let controlsViewController = controlsViewController {
//            loginProgressWindowController.window?.makeKeyAndOrderFront(self)
//

//        }
        if let resolutionObserver = resolutionObserver {
            NotificationCenter.default.removeObserver(resolutionObserver)
        }
        if let networkChangeObserver = networkChangeObserver {
            NotificationCenter.default.removeObserver(networkChangeObserver)

        }



        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 1.0
            context.allowsImplicitAnimation = true
            self.webView?.animator().alphaValue = 0.0
        }, completionHandler: {
                self.webView?.alphaValue = 0.0
            self.webView.removeFromSuperview()
//                self.window?.close()


        })
    }

    override func tokensUpdated(tokens: Creds) {
//if we have tokens, that means that authentication was successful.
//we have to check the password here so we can prompt.

        guard let delegate = delegate else {
            TCSLogErrorWithMark("invalid delegate")
            return
        }
        var username:String
        let defaultsUsername = DefaultsOverride.standardOverride.string(forKey: PrefKeys.username.rawValue)

        guard let idToken = tokens.idToken else {
            TCSLogErrorWithMark("invalid idToken")

            delegate.denyLogin(message:"The identity token is invalid")
            return
        }

        let array = idToken.components(separatedBy: ".")

        if array.count != 3 {
            TCSLogErrorWithMark("idToken is invalid")
            delegate.denyLogin(message:"The identity token is incorrect length.")
        }
        let body = array[1]
        TCSLogWithMark("base64 encoded IDToken: \(body)");
        guard let data = base64UrlDecode(value:body ) else {
            TCSLogErrorWithMark("error decoding id token base64")
            delegate.denyLogin(message:"The identity token could not be decoded from base64.")
            return
        }
        if let decodedTokenString = String(data: data, encoding: .utf8) {
            TCSLogWithMark("IDToken:\(decodedTokenString)")

        }
        let decoder = JSONDecoder()
        var idTokenObject:IDToken
        do {
            idTokenObject = try decoder.decode(IDToken.self, from: data)

        }
        catch {
            TCSLogErrorWithMark("error decoding idtoken::")
            TCSLogErrorWithMark("Token:\(body)")
            delegate.denyLogin(message:"The identity token could not be decoded from json.")
            return

        }

        let idTokenInfo = jwtDecode(value: idToken)  //dictionary for mapping

        // username static map
        if let defaultsUsername = defaultsUsername {
            username = defaultsUsername
        }
        else if let idTokenInfo = idTokenInfo, let mapKey = DefaultsOverride.standardOverride.object(forKey: "map_username")  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String, let leftSide = mapValue.components(separatedBy: "@").first{

            username = leftSide.replacingOccurrences(of: " ", with: "_").stripped
            TCSLogWithMark("mapped username found: \(mapValue) clean version:\(username)")


        }
        else {
            var emailString:String

            if let email = idTokenObject.email  {
                emailString=email.lowercased()
            }
            else if let uniqueName=idTokenObject.unique_name {
                emailString=uniqueName
            }

            else {
                TCSLogWithMark("no username found. Using sub.")
                emailString=idTokenObject.sub
            }
            guard let tUsername = emailString.components(separatedBy: "@").first?.lowercased() else {
                TCSLogErrorWithMark("email address invalid")
                delegate.denyLogin(message:"The email address from the identity token is invalid")
                return

            }

            TCSLogWithMark("username found: \(tUsername)")
            username = tUsername
        }

        //full name
        TCSLogWithMark("checking map_fullname")

        if let idTokenInfo = idTokenInfo, let mapKey = DefaultsOverride.standardOverride.object(forKey: "map_fullname")  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
            //we have a mapping so use that.
            TCSLogWithMark("full name mapped to: \(mapKey)")

            delegate.setHint(type: .fullName, hint: "\(mapValue)")

        }

        else if let firstName = idTokenObject.given_name, let lastName = idTokenObject.family_name {
            TCSLogWithMark("firstName: \(firstName)")
            TCSLogWithMark("lastName: \(lastName)")
            delegate.setHint(type: .fullName, hint: "\(firstName) \(lastName)")

        }
//groups
        if let idTokenInfo = idTokenInfo,let mapValue = idTokenInfo["groups"] as? Array<String> {
            TCSLogWithMark("setting groups: \(mapValue)")
            delegate.setHint(type: .groups, hint:mapValue)
        }
        else {

            TCSLogWithMark("No groups found")
        }

        //first name
        if let idTokenInfo = idTokenInfo, let mapKey = DefaultsOverride.standardOverride.object(forKey: "map_firstname")  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
//we have a mapping for username, so use that.
            TCSLogWithMark("first name mapped to: \(mapKey)")

            delegate.setHint(type: .firstName, hint:mapValue)
        }

       else if let firstName = idTokenObject.given_name {
           TCSLogWithMark("firstName from token: \(firstName)")

            delegate.setHint(type: .firstName, hint:firstName)

        }
        //last name
        TCSLogWithMark("checking map_lastname")

        if let idTokenInfo = idTokenInfo, let mapKey = DefaultsOverride.standardOverride.object(forKey: "map_lastname")  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
//we have a mapping for lastName, so use that.
            TCSLogWithMark("last name mapped to: \(mapKey)")

            delegate.setHint(type: .lastName, hint:mapValue)
        }

        else if let lastName = idTokenObject.family_name {
            TCSLogWithMark("lastName from token: \(lastName)")

            delegate.setHint(type: .lastName, hint:lastName)

        }
        TCSLogWithMark("checking local password for username:\(username) and password length: \(tokens.password.count)");

          let  passwordCheckStatus =  PasswordUtils.isLocalPasswordValid(userName: username, userPass: tokens.password)

        switch passwordCheckStatus {
        case .success:
            TCSLogWithMark("Local password matches cloud password ")
        case .incorrectPassword:
            TCSLogWithMark("local password is different from cloud password. Prompting for local password...")

            if DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue) != nil &&
                DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue) != nil &&
                getManagedPreference(key: .PasswordOverwriteSilent) as? Bool ?? false {
                TCSLogInfoWithMark("Set to write keychain silently and we have admin. Skipping.")
                delegate.setHint(type: .passwordOverwrite, hint: true)
                os_log("Hint set for passwordOverwrite", log: uiLog, type: .debug)
                break;
           }

            let passwordWindowController = LoginPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))

            if passwordWindowController.window==nil {
                TCSLogWithMark("no passwordWindowController window")
                delegate.denyLogin(message:"Unable to show password prompt")
                return
            }
            passwordWindowController.window?.canBecomeVisibleWithoutLogin=true
            passwordWindowController.window?.isMovable = false
            passwordWindowController.window?.canBecomeVisibleWithoutLogin = true
            passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
            var isDone = false
            while (!isDone){
                DispatchQueue.main.async{
                    TCSLogWithMark("resetting level")
                    passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
                }

                let response = NSApp.runModal(for: passwordWindowController.window!)
                if response == .cancel {
                    isDone=true
                    TCSLogWithMark("User cancelled resetting keychain or entering password. Denying login")
                    delegate.denyLogin(message:nil)
                    return

                }
                let resetKeychain = passwordWindowController.resetKeychain

                if resetKeychain == true {
                    os_log("Setting password to be overwritten.", log: uiLog, type: .default)
                    delegate.setHint(type: .passwordOverwrite, hint: true)

                    os_log("Hint set", log: uiLog, type: .debug)
                    passwordWindowController.window?.close()
                    isDone=true

                }
                else {
                    TCSLogWithMark("user gave old password. checking...")
                    let localPassword = passwordWindowController.password
                    guard let localPassword = localPassword else {
                        continue
                    }
                    let isValidPassword = PasswordUtils.isLocalPasswordValid(userName: username, userPass: localPassword)
                    switch isValidPassword {
                    case .success:
                        let localUser = try? PasswordUtils.getLocalRecord(username)
                        guard let localUser = localUser else {
                            TCSLogErrorWithMark("invalid local user")
                            delegate.denyLogin(message:"The local user \(username) could not be found")
                            return
                        }
                        do {
                            try localUser.changePassword(localPassword, toPassword: tokens.password)
                        }
                        catch {
                            TCSLogErrorWithMark("Error setting local password to cloud password")

                            delegate.denyLogin(message:error.localizedDescription)
                            return
                        }
                        TCSLogWithMark("setting original password to use to unlock keychain later")
                        delegate.setHint(type: .migratePass, hint: localPassword)
                        isDone=true
                        passwordWindowController.window?.close()
                        break
                    default:
                        passwordWindowController.window?.shake(self)

                    }
                }
            }
        case .accountDoesNotExist:
            TCSLogWithMark("user account doesn't exist yet")

        case .other(let mesg):
            TCSLogWithMark("password check error:\(mesg)")
            delegate.denyLogin(message:mesg)
            return
        }


        TCSLogWithMark("passing username:\(username), password, and tokens")
        TCSLogWithMark("setting kAuthorizationEnvironmentUsername")

        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: username)
        TCSLogWithMark("setting kAuthorizationEnvironmentPassword")

        delegate.setContextString(type: kAuthorizationEnvironmentPassword, value: tokens.password)
        TCSLogWithMark("setting username")

        delegate.setHint(type: .user, hint: username)
        TCSLogWithMark("setting tokens.password")

        delegate.setHint(type: .pass, hint: tokens.password)

        TCSLogWithMark("setting tokens")
        delegate.setHint(type: .tokens, hint: [tokens.idToken ?? "",tokens.refreshToken ?? "",tokens.accessToken ?? ""])
//        if let resolutionObserver = resolutionObserver {
//            NotificationCenter.default.removeObserver(resolutionObserver)
//        }
//
        DispatchQueue.main.async{
            TCSLogWithMark("calling allowLogin")

            self.delegate?.allowLogin()

//            self.loginTransition()

        }


    }
}


extension String {

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-._")
        return self.filter {okayChars.contains($0) }
    }
}
