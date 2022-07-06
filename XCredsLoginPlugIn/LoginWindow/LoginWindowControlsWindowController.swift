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
        setupLoginWindowControlsAppearance()
    }
    fileprivate func setupLoginWindowControlsAppearance() {
        self.window?.level = .screenSaver
        TCSLogWithMark("ordering controls front")
        self.window?.orderFrontRegardless()
        
        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true

        let screenRect = NSScreen.screens[0].frame
        let windowRec = NSMakeRect(0, 0, screenRect.width, self.window?.frame.height ?? 109)
        TCSLogWithMark("height is \(windowRec))")

        self.window?.setFrame(windowRec, display: true, animate: false)

    }
    @IBAction func restartClick(_ sender: Any) {
        TCSLogWithMark("Setting restart user")
        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for restart")

            return
        }
        delegate.setHint(type: .user, hint: SpecialUsers.restart.rawValue)
        delegate.allowLogin()
    }

    @IBAction func shutdownClick(_ sender: Any) {
        TCSLogWithMark("Setting shutdown user")
        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for shutdown")
            return
        }
        delegate.setHint(type: .user, hint: SpecialUsers.shutdown.rawValue)
        delegate.allowLogin()
    }
    @IBAction func resetToStandardLoginWindow(_ sender: Any) {
        TCSLogWithMark("resetting to standard login window")
        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for resetToStandardLoginWindow")
            return
        }
        delegate.setHint(type: .user, hint: SpecialUsers.standardLoginWindow.rawValue)
        delegate.allowLogin()
    }



}


