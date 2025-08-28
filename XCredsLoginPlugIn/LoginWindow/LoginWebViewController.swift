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
import OpenDirectory

class LoginWebViewController: WebViewController, DSQueryable {

    let uiLog = "uiLog"
//    var internalDelegate:XCredsMechanismProtocol?
    var mechanismDelegate:XCredsMechanismProtocol?
//    }
    @IBOutlet weak var backgroundImageView: NSImageView!

    override func awakeFromNib() {
//        NotificationCenter.default.addObserver(forName:NSApplication.didChangeScreenParametersNotification, object: nil, queue: nil) { notification in
//            TCSLogWithMark("Updating view")
//            self.updateView()
//        }
        TCSLogWithMark()

        updateView()
        
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { not in
            TCSLogWithMark("Waking from sleep, so refreshing view")
            self.updateView()
        }


    }
    
    override func viewDidLayout() {
        TCSLogWithMark()
    }

    override func viewWillLayout() {
        TCSLogWithMark()
        updateView()
    }
    func updateView(){
        self.view.layer?.cornerRadius=15

        let screenRect = NSScreen.screens[0].frame

        let screenWidth = screenRect.width
        let screenHeight = screenRect.height

        var loginWindowWidth = screenWidth //start with full size
        var loginWindowHeight = screenHeight //start with full size

        if DefaultsOverride.standardOverride.object(forKey: PrefKeys.loginWindowWidth.rawValue) != nil  {
            let val = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowWidth.rawValue))
            if val > 149 {
                TCSLogWithMark("setting loginWindowWidth to \(val)")
                loginWindowWidth = val
            }
        }
        if DefaultsOverride.standardOverride.object(forKey: PrefKeys.loginWindowHeight.rawValue) != nil {
            let val = CGFloat(DefaultsOverride.standardOverride.float(forKey: PrefKeys.loginWindowHeight.rawValue))
            if val > 149 {
                TCSLogWithMark("setting loginWindowHeight to \(val)")
                loginWindowHeight = val
            }
        }
        TCSLogWithMark("setting loginWindowWidth to \(loginWindowWidth)")

        TCSLogWithMark("setting loginWindowHeight to \(loginWindowHeight)")

        view.setFrameSize(NSMakeSize(loginWindowWidth, loginWindowHeight))
        
        loadPage()
        

    }
    override func viewDidAppear() {
        TCSLogWithMark("loading page")
        //if prefs define smaller, then resize window
        TCSLogWithMark("checking for custom height and width")
        updateView()
    }


    override func showErrorMessageAndDeny(_ message:String){
            mechanismDelegate?.denyLogin(message:message)
            return
        }


    override func credentialsUpdated(_ credentials:Creds){
        
        if let res = mechanismDelegate?.setupHints(fromCredentials: credentials, password: password ?? "" ){

            switch res {

            case .success:
                break
            case .failure(let message):
                TCSLogWithMark("error setting up hints, reloading page:\(message)")
                let alert = NSAlert()
                alert.addButton(withTitle: "OK")
                alert.messageText=message

                alert.window.canBecomeVisibleWithoutLogin=true

                let bundle = Bundle.findBundleWithName(name: "XCreds")

                if let bundle = bundle {
                    TCSLogWithMark("Found bundle")

                    alert.icon=bundle.image(forResource: NSImage.Name("icon_128x128"))

                }
                alert.runModal()

                self.updateView()


            case .userCancelled:
                TCSLogWithMark("user cancelled")

                self.updateView()

            }
        }

    }

}



extension String {

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-._")
        return self.filter {okayChars.contains($0) }
    }
}
