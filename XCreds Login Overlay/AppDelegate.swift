//
//  AppDelegate.swift
//  XCreds Login Overlay
//
//  Created by Timothy Perfitt on 7/16/22.
//

import Cocoa
import AppKit



@main
struct MyMain {
    static func resetRights() ->Bool {

        if AuthorizationDBManager.shared.rightExists(right:"XCredsLoginPlugin:LoginWindow")==true {
            TCSLogWithMark("replacing XCredsLoginPlugin:LoginWindow with loginwindow:login")
            if AuthorizationDBManager.shared.replace(right: "XCredsLoginPlugin:LoginWindow", withNewRight: "loginwindow:login") == false {
                TCSLogErrorWithMark("Error removing XCredsLoginPlugin:LoginWindow. bailing")
                return false

            }
        }
        else if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login")==false {
            TCSLogErrorWithMark("There was no XCredsLoginPlugin:LoginWindow and no loginwindow:login. Please remove /var/db/auth.db and reboot")
            return false
        }




        for authRight in AuthorizationDBManager.shared.consoleRights() {
            if authRight.hasPrefix("XCredsLoginPlugin") {
                TCSLogWithMark("Removing \(authRight)")
                if AuthorizationDBManager.shared.remove(right: authRight) == false {
                    TCSLogErrorWithMark("Error removing \(authRight)")

                }
            }

        }
        return true

    }
    static func addRights() ->Bool {

        TCSLogWithMark("Adding rights back in")
        if AuthorizationDBManager.shared.replace(right: "loginwindow:login", withNewRight: "XCredsLoginPlugin:LoginWindow")==false {
            TCSLogWithMark("error adding loginwindow:login after XCredsLoginPlugin:LoginWindow. bailing since this shouldn't happen")

            return false

        }

        for right in [["XCredsLoginPlugin:LoginWindow":"XCredsLoginPlugin:PowerControl,privileged"], ["loginwindow:done":"XCredsLoginPlugin:KeychainAdd,privileged"],["builtin:login-begin":"XCredsLoginPlugin:CreateUser,privileged"],["loginwindow:done":"XCredsLoginPlugin:EnableFDE,privileged"],["loginwindow:done":"XCredsLoginPlugin:LoginDone"]] {

            if AuthorizationDBManager.shared.rightExists(right: right.keys.first!){

                if AuthorizationDBManager.shared.insertRight(newRight: right.values.first!, afterRight: right.keys.first!) {


                    TCSLogWithMark("adding \(right.values.first!) after \(right.keys.first!)")
                }

                else {
                    TCSLogErrorWithMark("\(right.keys.first!) does not exist. not inserting \(right.values.first!)")
                }

            }
        }
        return true

    }

    static func main() -> Void {
        if AuthorizationDBManager.shared.rightExists(right: "XCredsLoginPlugin:LoginWindow") == true {
            TCSLogWithMark("XCreds auth rights already installed.")

            return
        }
        TCSLogErrorWithMark("XCreds rights do not exist. Fixing and rebooting")

        if resetRights()==false {
            TCSLogErrorWithMark("error resetting rights")
            return
        }
        if addRights()==false {
            TCSLogErrorWithMark("error adding rights")

        }
        let _ = cliTaskNoTerm("/sbin/reboot")

    }

}

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var cloudLoginTextField: NSTextField!
    @IBOutlet var window: NSWindow!
    @IBOutlet var waitWindow: NSWindow!

    @IBAction func cloudLoginButtonPressed(_ sender: Any) {

        waitWindow.level = .modalPanel
        waitWindow.canBecomeVisibleWithoutLogin = true
        let screenRect = NSScreen.screens[0].visibleFrame

        let screenWidth = screenRect.width
        let screenHeight = screenRect.height
        let waitWindowWidth = waitWindow.frame.width

        let newPos = NSMakePoint(screenWidth/2-waitWindowWidth/2, screenHeight/2)
        waitWindow.setFrameOrigin(newPos)
        waitWindow.makeKeyAndOrderFront(self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login"){
                TCSLogWithMark("setting standard login back to XCreds login")
                try? "".write(toFile: "/tmp/xcreds_return", atomically: false, encoding: .utf8)
                let _ = AuthorizationDBManager.shared.replace(right:"loginwindow:login", withNewRight: "XCredsLoginPlugin:LoginWindow")
                let _ = cliTask("/usr/bin/killall loginwindow")

            }
        }
    }

/*
 (void)showStatusBar:(__unused id)sender{

     [self updateStatus:self];
     [self.returnToBootRunnerWindow setLevel:NSScreenSaverWindowLevel];


     [self.returnToBootRunnerWindow setCanBecomeVisibleWithoutLogin:YES];
     [self.returnToBootRunnerWindow setHidesOnDeactivate:NO];
     [self.returnToBootRunnerWindow setOpaque:NO];
     [self.returnToBootRunnerWindow orderFront:self];

     NSRect statusWindowRect=self.returnToBootRunnerWindow.frame;
     NSRect screenRect=[[[NSScreen screens] objectAtIndex:0] visibleFrame];

     statusWindowRect.size.width=screenRect.size.width;
     statusWindowRect.origin=screenRect.origin;
     [self.returnToBootRunnerWindow setFrame:statusWindowRect display:YES];

 }


 */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login") == true {
//
//            var statusWindowRect=window.frame
//            let screenRect = NSScreen.screens[0].visibleFrame
//            statusWindowRect.size.width=screenRect.size.width
//            statusWindowRect.origin=screenRect.origin;
//            window.setFrame(statusWindowRect, display: true, animate: false)
//            window.canBecomeVisibleWithoutLogin=true
//            window.hidesOnDeactivate=false
//            window.isOpaque=false
//            window.level = .modalPanel
//            //        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
//            //            NSApp.activate(ignoringOtherApps: true)
//            //            self.window.orderFrontRegardless()
//            //        }
//
//            NSApp.activate(ignoringOtherApps: true)
//            window.orderFrontRegardless()
//            if let ud = UserDefaults(suiteName: "com.twocanoes.xcreds"),  let customTextString = ud.value(forKey: "cloudLoginText") {
//                cloudLoginTextField.stringValue = customTextString as! String
//                cloudLoginTextField.sizeToFit()
//
//            }
//        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

