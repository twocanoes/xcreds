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
    static func main() -> Void {
        sleep(5)
         let _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

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

      


        var statusWindowRect=window.frame
        let screenRect = NSScreen.screens[0].visibleFrame


        statusWindowRect.size.width=screenRect.size.width
        statusWindowRect.origin=screenRect.origin;
        window.setFrame(statusWindowRect, display: true, animate: false)

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

