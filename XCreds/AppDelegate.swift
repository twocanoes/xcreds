//
//  AppDelegate.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationCenter.default.addObserver(forName: Notification.Name("TCSTokensUpdated"), object: nil, queue: nil) { notification in
//            ScheduleManager.shared.startCredentialCheck()

            let alertController = NSAlert()
            alertController.messageText = "Local Password"
            alertController.addButton(withTitle: "OK")
            alertController.addButton(withTitle: "Cancel")

            let localPassword = NSSecureTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 24))
            localPassword.becomeFirstResponder()

            alertController.accessoryView = localPassword
            alertController.runModal()

        }
        mainMenu.statusBarItem.menu = mainMenu.mainMenu
        ScheduleManager.shared.startCredentialCheck()
        var password:String?
        while (true){
            let alertController = NSAlert()

            alertController.messageText = "Please enter your local password"
            alertController.addButton(withTitle: "OK")
            alertController.addButton(withTitle: "Cancel")

            let localPassword = NSSecureTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 24))

            alertController.accessoryView = localPassword
            localPassword.becomeFirstResponder()

            let response = alertController.runModal()


            if response == .alertSecondButtonReturn {
                break
            }
            let isPasswordValid = PasswordUtils.verifyCurrentUserPassword(password: localPassword.stringValue)
            if isPasswordValid==true {
                password=localPassword.stringValue
                break
            }
        }

        if let password = password {

            NotifyManager.shared.sendMessage(message: "valid password")
        }
        else {
            NotifyManager.shared.sendMessage(message: "cancelled")
        }


        do {
            
             let isPasswordValid = PasswordUtils.verifyCurrentUserPassword(password: "asdfasfd")

            if isPasswordValid {
                print("good password")
            }
            else {
                print("bad password")

            }
        }



    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

