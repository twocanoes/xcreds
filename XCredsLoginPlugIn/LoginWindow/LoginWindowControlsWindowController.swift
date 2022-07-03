//
//  LoginWindowControlsWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/3/22.
//

import Cocoa

class LoginWindowControlsWindowController: NSWindowController {
    var delegate: XCredsMechanismProtocol?

    override func windowDidLoad() {
        super.windowDidLoad()
        setupLoginWindowAppearance()
    }
    fileprivate func setupLoginWindowAppearance() {
        self.window?.level = .screenSaver
        TCSLog("ordering controls front")
        self.window?.orderFrontRegardless()
        
        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true

        let screenRect = NSScreen.screens[0].frame
        let windowRec = NSMakeRect(0, 0, screenRect.width, self.window?.frame.height ?? 100)
        self.window?.setFrame(windowRec, display: true, animate: false)

    }
    @IBAction func restartClick(_ sender: Any) {
        TCSLog("Setting restart user")
        guard let delegate = delegate else {
            TCSLog("No delegate set for restart")

            return
        }
        delegate.setHint(type: .user, hint: SpecialUsers.restart.rawValue)
        delegate.allowLogin()
    }

    @IBAction func shutdownClick(_ sender: Any) {
        TCSLog("Setting shutdown user")
        guard let delegate = delegate else {
            TCSLog("No delegate set for shutdown")
            return
        }
        delegate.setHint(type: .user, hint: SpecialUsers.shutdown.rawValue)
        delegate.allowLogin()
    }

}


