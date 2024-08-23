//
//  AppDelegate.swift
//  XCreds AutoFill
//
//  Created by Timothy Perfitt on 6/5/24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    static func main() {
        if CommandLine.arguments.contains("-r") {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+5) {
                NSApplication.shared.terminate(self)
            }
        }
        let app = NSApplication.shared
        let appDelegate = AppDelegate()
        app.delegate = appDelegate
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)


    }





    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

