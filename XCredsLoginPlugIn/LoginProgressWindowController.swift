//
//  LoginProgressWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 8/9/22.
//

import Cocoa

class LoginProgressWindowController: NSWindowController {
    @IBOutlet weak var backgroundImageView: NSImageView!

    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    override func windowDidLoad() {
        super.windowDidLoad()


        NotificationCenter.default.addObserver(forName: NSNotification.Name("hideProgress"), object:nil, queue: nil) { notification in
            TCSLogWithMark("Got notified to hide progress.")
            self.window?.close()
        }
        TCSLogWithMark("Showing progress...")
        progressIndicator.startAnimation(self)
//        progressIndicator.controlTint = .graphiteControlTint
        self.window?.canBecomeVisibleWithoutLogin=true

        self.window?.level = .normal
        self.window?.orderFrontRegardless()

        self.window?.backgroundColor = NSColor.white

        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false

        let screenRect = NSScreen.screens[0].frame
        self.window?.setFrame(screenRect, display: true, animate: false)
        self.window?.alphaValue=0.9

        let backgroundImage = DefaultsHelper.backgroundImage(includeDefault: false)

        if let backgroundImage = backgroundImage {
            backgroundImage.size=screenRect.size
            backgroundImageView.image = backgroundImage

            backgroundImage.size=screenRect.size
            backgroundImageView.image=backgroundImage
            backgroundImageView.imageScaling = .scaleProportionallyUpOrDown

            backgroundImageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)

        }


    }
    
}
