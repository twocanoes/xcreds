import Cocoa
import os.log

@objc class XCredsMechanism: NSObject {
    let mechCallbacks: AuthorizationCallbacks
    let mechEngine: AuthorizationEngineRef
    let mech: MechanismRecord?
    @objc var loginWindow: XCredsMechanism!
    @objc var webViewController: LoginWebViewController!
    @objc init(mechanism: UnsafePointer<MechanismRecord>) {
        TCSLog("\(#function) \(#file):\(#line)")

        self.mech = mechanism.pointee
        self.mechCallbacks = mechanism.pointee.fPlugin.pointee.fCallbacks.pointee
        self.mechEngine = mechanism.pointee.fEngine

        super.init()
        setupPrefs()

    }

    @objc func show() {
        TCSLog("\(#function) \(#file):\(#line)")


        NSApp.activate(ignoringOtherApps: true)

        webViewController = LoginWebViewController(windowNibName: NSNib.Name("LoginWebView"))

        guard webViewController.window != nil else {
            TCSLog("could not create xcreds window")
            return
        }

        webViewController.window?.makeKeyAndOrderFront(self)


    }
    func setupPrefs(){
        UserDefaults.standard.addSuite(named: "com.twocanoes.xcreds")
        let defaultsPath = Bundle(for: type(of: self)).path(forResource: "defaults", ofType: "plist")

        if let defaultsPath = defaultsPath {

            let defaultsDict = NSDictionary(contentsOfFile: defaultsPath)
            UserDefaults.standard.register(defaults: defaultsDict as! [String : Any])
        }


    }


    func allowLogin() {
        TCSLog("\(#function) \(#file):\(#line)")
        let error = mechCallbacks.SetResult(mechEngine, .allow)
        if error != noErr {
        }
    }

    // disallow login
    func denyLogin() {
        TCSLog("\(#function) \(#file):\(#line)")

        let error = mechCallbacks.SetResult(mechEngine, .deny)
        if error != noErr {
        }
    }

}
