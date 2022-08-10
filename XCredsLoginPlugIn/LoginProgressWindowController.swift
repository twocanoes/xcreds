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

            TCSLogWithMark("gotnotification")
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

        if let path = UserDefaults.standard.string(forKey: PrefKeys.loginWindowBackgroundImagePath.rawValue) {
            let image = NSImage.init(contentsOfFile: path)
            image?.size=screenRect.size
            backgroundImageView.image = image


        }


    }
    
}
