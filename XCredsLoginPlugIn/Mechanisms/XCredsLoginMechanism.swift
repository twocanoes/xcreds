import Cocoa
import os.log

@objc class XCredsLoginMechanism: XCredsBaseMechanism {
    @objc var loginWindow: XCredsLoginMechanism!
    @objc var webViewController: LoginWebViewController!
    @objc var loginWindowControlsWindowController:LoginWindowControlsWindowController!

    override init(mechanism: UnsafePointer<MechanismRecord>) {
        super.init(mechanism: mechanism)

    }
  

    @objc override func run() {
        TCSLog("\(#function) \(#file):\(#line)")
        NSApp.activate(ignoringOtherApps: true)

        webViewController = LoginWebViewController(windowNibName: NSNib.Name("LoginWebView"))

        guard webViewController.window != nil else {
            TCSLog("could not create xcreds window")
            return
        }
        webViewController.delegate=self

        loginWindowControlsWindowController = LoginWindowControlsWindowController(windowNibName: NSNib.Name("LoginWindowControls"))

        guard loginWindowControlsWindowController.window != nil else {
            TCSLog("could not create loginWindowControlsWindowController window")
            return
        }
        loginWindowControlsWindowController.delegate=self

    }
}
