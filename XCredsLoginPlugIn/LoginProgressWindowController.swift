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



        progressIndicator.startAnimation(self)
        self.window?.canBecomeVisibleWithoutLogin=true

        self.window?.level = .popUpMenu
        self.window?.orderFrontRegardless()

        self.window?.backgroundColor = NSColor.systemGray

        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false

        let screenRect = NSScreen.screens[0].frame
        self.window?.setFrame(screenRect, display: true, animate: false)

        if let pathURLString = UserDefaults.standard.string(forKey: PrefKeys.loginWindowBackgroundImageURL.rawValue), let image = NSImage.imageFromPathOrURL(pathURLString: pathURLString){
            image.size=screenRect.size
            backgroundImageView.image = image
        }
    }
    
}
