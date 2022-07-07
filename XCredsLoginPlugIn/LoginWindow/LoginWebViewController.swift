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
        setupLoginWindowAppearance()
        loadPage()
    }
    fileprivate func setupLoginWindowAppearance() {
        self.window?.level = .popUpMenu
        self.window?.orderFrontRegardless()

        self.window?.backgroundColor = NSColor.black

        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true

        let screenRect = NSScreen.screens[0].frame
        self.window?.setFrame(screenRect, display: true, animate: false)

    }

    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("LoginWebView")
    }
    func loginTransition() {

        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 1.0
            context.allowsImplicitAnimation = true
            self.window?.alphaValue = 0.0
        }, completionHandler: {
            self.window?.close()
        })
    }

    override func tokensUpdated(tokens: Tokens) {
//if we have tokens, that means that authentication was successful.
        //we have to check the password here so we can prompt.

        guard let delegate = delegate else {
            TCSLogWithMark("invalid delegate")
            return
        }

        let isLocal = try? PasswordUtils.isUserLocal("tperfitt")

        guard let isLocal = isLocal else {
            TCSLogWithMark("cannot find if user is local")
            return
        }

        if isLocal == false {
            TCSLogWithMark("User is not on system. for now, just abort")
            delegate.denyLogin()
            return
        }
        let isValidPassword =  try? PasswordUtils.isLocalPasswordValid(userName: "tperfitt", userPass: tokens.password)

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
                let isValidPassword =  try? PasswordUtils.isLocalPasswordValid(userName: "tperfitt", userPass: localPassword)

                if isValidPassword==true {
                    let localUser = try? PasswordUtils.getLocalRecord("tperfitt")
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
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: "tperfitt")
        delegate.setContextString(type: kAuthorizationEnvironmentPassword, value: tokens.password)

        delegate.setHint(type: .tokens, hint: [tokens.idToken,tokens.refreshToken,tokens.accessToken])

        RunLoop.main.perform {
            self.loginTransition()
        }
        delegate.allowLogin()


    }
}


