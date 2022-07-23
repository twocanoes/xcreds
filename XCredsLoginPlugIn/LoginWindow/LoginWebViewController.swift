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

class LoginWebViewController: WebViewController {

    var delegate: XCredsMechanismProtocol?
    override func windowDidLoad() {
        super.windowDidLoad()
        TCSLogWithMark("loading webview for login")
        setupLoginWindowAppearance()
        TCSLogWithMark("loading page")
        loadPage()
    }
    fileprivate func setupLoginWindowAppearance() {
        DispatchQueue.main.async {
            TCSLogWithMark("setting up window")

            
            self.window?.level = .popUpMenu
            self.window?.orderFrontRegardless()
            
            self.window?.backgroundColor = NSColor.black
            
            self.window?.titlebarAppearsTransparent = true
            
            self.window?.isMovable = false
            self.window?.canBecomeVisibleWithoutLogin = true
            
            let screenRect = NSScreen.screens[0].frame
            self.window?.setFrame(screenRect, display: true, animate: false)
        }
        
    }

    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("LoginWebView")
    }
    func loginTransition() {

        let screenRect = NSScreen.screens[0].frame
        let progressIndicator=NSProgressIndicator.init(frame: NSMakeRect(screenRect.width/2-16  , 3*screenRect.height/4-16,32, 32))
        progressIndicator.style = .spinning
        progressIndicator.startAnimation(self)
        webView.addSubview(progressIndicator)
//        NSAnimationContext.runAnimationGroup({ (context) in
//            context.duration = 1.0
//            context.allowsImplicitAnimation = true
//            self.window?.alphaValue = 0.0
//        }, completionHandler: {
//            self.window?.close()
//        })
    }

    override func tokensUpdated(tokens: Tokens) {
//if we have tokens, that means that authentication was successful.
        //we have to check the password here so we can prompt.

        guard let delegate = delegate else {
            TCSLogWithMark("invalid delegate")
            return
        }
        var username:String
        let defaultsUsername = UserDefaults.standard.string(forKey: PrefKeys.username.rawValue)

        let idToken = tokens.idToken

        let array = idToken.components(separatedBy: ".")

        if array.count != 3 {
            TCSLogWithMark("idToken is invalid")
            delegate.denyLogin()


        }
        let body = array[1]
        guard let data = base64UrlDecode(value:body ) else {
            TCSLogWithMark("error decoding id token base64")
            delegate.denyLogin()
            return
        }

        
        let decoder = JSONDecoder()
        var idTokenObject:IDToken
        do {
            idTokenObject = try decoder.decode(IDToken.self, from: data)

        }
        catch {
            TCSLogWithMark("error decoding idtoken::")
            TCSLogWithMark("Token:\(body)")
            delegate.denyLogin()
            return

        }


        if let defaultsUsername = defaultsUsername {
            username = defaultsUsername
        }
        else {


            var emailString:String


            if idTokenObject.email != nil {
                emailString=idTokenObject.email!.lowercased()
            }
            else if idTokenObject.unique_name != nil {
                emailString=idTokenObject.unique_name!
            }
            else {
                TCSLogWithMark("no username found or invalid")
                delegate.denyLogin()
                return

            }
            guard let tUsername = emailString.components(separatedBy: "@").first?.lowercased() else {
                TCSLogWithMark("email address invalid")
                delegate.denyLogin()
                return

            }

            TCSLogWithMark("username found: \(tUsername)")
            username = tUsername
        }

        if let firstName = idTokenObject.given_name, let lastName = idTokenObject.family_name {
            delegate.setHint(type: .fullName, hint: "\(firstName) \(lastName)")

        }
        if let firstName = idTokenObject.given_name {
            delegate.setHint(type: .firstName, hint:firstName)

        }
        if let lastName = idTokenObject.family_name {
            delegate.setHint(type: .lastName, hint:lastName)

        }

        let isLocal = try? PasswordUtils.isUserLocal(username)

        guard let isLocal = isLocal else {
            TCSLogWithMark("cannot find if user is local")
            delegate.denyLogin()
            return
        }

        if isLocal == false {
            TCSLogWithMark("User is not on system. for now, just abort")
            delegate.denyLogin()
            return
        }

        let hasHome = try? PasswordUtils.doesUserHomeExist(username)
        guard let hasHome = hasHome else {
            TCSLogWithMark("home dir nil")
            delegate.denyLogin()
            return
        }

        if hasHome == false {
            TCSLogWithMark("User has no home. for now, just abort")
            delegate.denyLogin()
            return
        }



        let isValidPassword =  try? PasswordUtils.isLocalPasswordValid(userName: username, userPass: tokens.password)

        if isValidPassword==false{
            TCSLogWithMark("local password is different from cloud password. Prompting for local password.")

            let passwordWindowController = LoginPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))

            if passwordWindowController.window==nil {
                TCSLogWithMark("no passwordWindowController window")
                delegate.denyLogin()
                return
            }
            passwordWindowController.window?.canBecomeVisibleWithoutLogin=true
            passwordWindowController.window?.isMovable = false
            passwordWindowController.window?.canBecomeVisibleWithoutLogin = true
            passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
            while (true){
//                NSApp.activate(ignoringOtherApps: true)
                DispatchQueue.main.async{
                    TCSLogWithMark("resetting level")
                    passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue)
                }
                TCSLogWithMark("showing modal")

                let response = NSApp.runModal(for: passwordWindowController.window!)

                TCSLogWithMark("modal done")
                if response == .cancel {
                    break
                }
                let localPassword = passwordWindowController.password
                guard let localPassword = localPassword else {
                    continue
                }
                let isValidPassword =  try? PasswordUtils.isLocalPasswordValid(userName: username, userPass: localPassword)

                if isValidPassword==true {
                    let localUser = try? PasswordUtils.getLocalRecord(username)
                    guard let localUser = localUser else {
                        TCSLogWithMark("invalid local user")
                        delegate.denyLogin()
                        return
                    }
                    do {
                        try localUser.changePassword(localPassword, toPassword: tokens.password)
                    }
                    catch {
                        TCSLogWithMark("Error setting local password to cloud password")
                        delegate.denyLogin()
                        return
                    }
                    TCSLogWithMark("setting original password to use to unlock keychain later")
                    delegate.setHint(type: .migratePass, hint: localPassword)
                    passwordWindowController.window?.close()
                    break

                }
                else{
                    passwordWindowController.window?.shake(self)
                }
            }

        }
        TCSLogWithMark("updating username, password, and tokens")
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: username)
        delegate.setContextString(type: kAuthorizationEnvironmentPassword, value: tokens.password)

        delegate.setHint(type: .tokens, hint: [tokens.idToken,tokens.refreshToken,tokens.accessToken])

        RunLoop.main.perform {
            self.loginTransition()
        }
        delegate.allowLogin()


    }
}


