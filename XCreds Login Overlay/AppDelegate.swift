//
//  AppDelegate.swift
//  XCreds Login Overlay
//
//  Created by Timothy Perfitt on 7/16/22.
//

import Cocoa
import AppKit




@main
class App {
    static func main() {
        sleep(5)
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
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
    func setupWindow()  {
        var statusWindowRect=window.frame
        let screenRect = NSScreen.screens[0].visibleFrame
        statusWindowRect.size.width=screenRect.size.width
        statusWindowRect.origin=screenRect.origin;
        window.setFrame(statusWindowRect, display: true, animate: false)
        window.canBecomeVisibleWithoutLogin=true
        window.hidesOnDeactivate=false
        window.isOpaque=false
        window.level = .modalPanel
        if let ud = UserDefaults(suiteName: "com.twocanoes.xcreds"),  let customTextString = ud.value(forKey: "cloudLoginText") {
            cloudLoginTextField.stringValue = customTextString as! String
            cloudLoginTextField.sizeToFit()

        }
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login") == true {


            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
                NSApp.activate(ignoringOtherApps: true)
                self.window.orderFrontRegardless()
                DispatchQueue.main.async {


                    self.setupWindow()
                }
            }
            setupWindow()
            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

