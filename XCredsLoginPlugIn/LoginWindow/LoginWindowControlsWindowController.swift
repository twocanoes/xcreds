//
//  LoginWindowControlsWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/3/22.
//

import Cocoa

class LoginWindowControlsWindowController: NSWindowController {
    var delegate: XCredsMechanismProtocol?

    let uiLog = "uiLog"

    var wifiWindowController:WifiWindowController?
    override func windowDidLoad() {
        super.windowDidLoad()
        setupLoginWindowControlsAppearance()
        NotificationCenter.default.addObserver(forName:NSApplication.didChangeScreenParametersNotification, object: nil, queue: nil) { notification in
            TCSLogWithMark("Resolution changed. Resetting size")
            self.setupLoginWindowControlsAppearance()


        }

    }
    fileprivate func setupLoginWindowControlsAppearance() {
        DispatchQueue.main.async {

            self.window?.level = .screenSaver
            TCSLogWithMark("ordering controls front")
            self.window?.orderFrontRegardless()

            self.window?.titlebarAppearsTransparent = true
            self.window?.isMovable = false
            self.window?.canBecomeVisibleWithoutLogin = true

            let screenRect = NSScreen.screens[0].frame
            let windowRec = NSMakeRect(0, 0, screenRect.width,109)
            TCSLogWithMark("screens: \(NSScreen.screens) height is \(windowRec), secreenredc is \(screenRect)")

            self.window?.setFrame(windowRec, display: true, animate: false)
            self.window?.viewsNeedDisplay=true
            TCSLogWithMark("height is \(String(describing: self.window?.frame))")
        }

    }
    @IBAction func showNetworkConnection(_ sender: Any) {
//        username.isHidden = true
        TCSLogWithMark()

        wifiWindowController = WifiWindowController(windowNibName: NSNib.Name("WifiWindowController"))
        TCSLogWithMark()

        guard let windowController = wifiWindowController, let window = windowController.window else {
            TCSLogWithMark("no window for wifi")
            return
        }
        TCSLogWithMark("setting window level")

        window.level = .screenSaver+2
        TCSLogWithMark("wifiWindowController ordering controls front")
        window.orderFrontRegardless()
        TCSLogWithMark()
        window.titlebarAppearsTransparent = true
        window.isMovable = true
        window.canBecomeVisibleWithoutLogin = true
        window.makeKeyAndOrderFront(self)

        window.titlebarAppearsTransparent = true


        let screenRect = NSScreen.screens[0].frame
        window.setFrame(screenRect, display: true, animate: false)


        TCSLogWithMark()
//        guard let wifiWindowController = WifiWindowViewController.createFr.createFromNib(in: .mainLogin) else {
//            os_log("Error showing network selection.", log: uiLog, type: .debug)
//            return
//        }
//
        
//        wifiView.frame = windowContentView.frame
//        let completion = {
//            os_log("Finished working with wireless networks", log: self.uiLog, type: .debug)
////            self.username.isHidden = false
////            self.username.becomeFirstResponder()
//        }
//        wifiView.set(completionHandler: completion)
//        windowContentView.addSubview(wifiView)
    }


    @IBAction func restartClick(_ sender: Any) {
        TCSLogWithMark("Setting restart user")
        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for restart")

            return
        }
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.restart.rawValue)

        delegate.allowLogin()
    }

    @IBAction func shutdownClick(_ sender: Any) {
        TCSLogWithMark("Setting shutdown user")
        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for shutdown")
            return
        }
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.shutdown.rawValue)

        delegate.allowLogin()
    }
    @IBAction func resetToStandardLoginWindow(_ sender: Any) {
        TCSLogWithMark("resetting to standard login window")
        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for resetToStandardLoginWindow")
            return
        }
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.standardLoginWindow.rawValue)

        delegate.allowLogin()
    }



}


