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
        TCSLog("ordering loignwindow front")

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

        TCSLog("updating username and password")
        guard let delegate = delegate else {
            return
        }

        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: "tperfitt")
        delegate.setContextString(type: kAuthorizationEnvironmentPassword, value: tokens.password)
        delegate.allowLogin()
        RunLoop.main.perform {
            self.loginTransition()

        }

    }
}


