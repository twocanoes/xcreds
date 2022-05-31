//
//  SignInMenuItem.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class SignInMenuItem: NSMenuItem {

    override var title: String {
        get {
            "Sign In..."
        }
        set {
            return
        }
    }

    init() {
         super.init(title: "", action: #selector(doAction), keyEquivalent: "")
         self.target = self
     }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func doAction() {

        mainMenu.webView = WebViewController()
        mainMenu.webView?.window!.forceToFrontAndFocus(nil)
        mainMenu.webView?.run()
    }
}
