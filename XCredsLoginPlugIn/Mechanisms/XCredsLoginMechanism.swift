import Cocoa


@objc class XCredsLoginMechanism: XCredsBaseMechanism {
    @objc var loginWindow: XCredsLoginMechanism!
    @objc var webViewController: LoginWebViewController!
    @objc var loginWindowControlsWindowController:LoginWindowControlsWindowController!

    override init(mechanism: UnsafePointer<MechanismRecord>) {
        super.init(mechanism: mechanism)

    }
    override func reload() {
        TCSLogWithMark("reload in controller")
        webViewController.loadPage()
    }

    @objc override func run() {
        TCSLogWithMark("\(#function) \(#file):\(#line)")
        NSApp.activate(ignoringOtherApps: true)

        webViewController = LoginWebViewController(windowNibName: NSNib.Name("LoginWebView"))

        guard webViewController.window != nil else {
            TCSLogWithMark("could not create xcreds window")
            return
        }
        webViewController.delegate=self

        loginWindowControlsWindowController = LoginWindowControlsWindowController(windowNibName: NSNib.Name("LoginWindowControls"))

        guard loginWindowControlsWindowController.window != nil else {
            TCSLogWithMark("could not create loginWindowControlsWindowController window")
            return
        }
        loginWindowControlsWindowController.delegate=self

    }
    override func allowLogin() {

        loginWindowControlsWindowController.dismiss()
        super.allowLogin()
    }
    override func denyLogin() {
        loginWindowControlsWindowController.close()
        super.denyLogin()
    }
}
