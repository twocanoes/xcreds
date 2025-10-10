//
//  AppDelegate.swift
//  FileVaultLogin
//
//  Created by Timothy Perfitt on 10/8/25.
//

import Cocoa
import os.log
import ServiceManagement
@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    let helperToolManager = HelperToolManager()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.addSuite(named: "com.twocanoes.xcreds")

        TCSLogWithMark()
        switch  helperToolManager.manageHelperTool(action: .install) {
            
        case .notRegistered:
            TCSLogWithMark()

            NSAlert.showAlert(title: "Error", message:"Service is not registered")
            return
        case .enabled:
            TCSLogWithMark()

            break
        case .requiresApproval:
            TCSLogWithMark("Service requires approval. Please select Allow in the notification or open System Preferences->Login Items and allow the service")

//            NSAlert.showAlert(title: "Error",message:"Service requires approval. Please select Allow in the notification or open System Preferences->Login Items and allow the service.")
            SMAppService.openSystemSettingsLoginItems()
            return
        case .notFound:
            NSAlert.showAlert(title: "Error",message:"Service Not Found")
            return
        @unknown default:
            NSAlert.showAlert(title: "Error",message:"Unknown Error")
            return
        }
       
        TCSLogWithMark()

        let username = getConsoleUser()
        let cred = KeychainUtil().findPassword(serviceName: "xcreds local password", accountName: "xcreds local password")
        TCSLogWithMark()

        guard let cred = cred else {
            
            TCSLogWithMark("no valid password found")
//            NSAlert.showAlert(title:"Error",message:"No valid password found in keychain. If you have not logged out and logged in, please do so now.")
            NSApplication.shared.terminate(self)

            return
            
        }
        helperToolManager.runCommand(username:username, password:cred.password) { output in
            if output==true{
                TCSLogWithMark("runCommand success")
                NSApplication.shared.terminate(self)
            }
            else {
                TCSLogWithMark()

                NSAlert.showAlert(title:"Error",message:"Cannot set filevault login")
                NSApplication.shared.terminate(self)
            }
        }
        TCSLogWithMark()

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

