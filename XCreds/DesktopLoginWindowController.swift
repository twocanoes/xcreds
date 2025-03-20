//
//  DesktopLoginWindow.swift
//  XCreds
//
//  Created by Timothy Perfitt on 12/11/23.
//

import Cocoa

class DesktopLoginWindowController: NSWindowController {
    @IBOutlet var webViewController: WebViewController!
    @IBOutlet var backgroundImageView:NSImageView!

    override class func awakeFromNib() {
        
    }
    override func windowDidLoad() {
        super.windowDidLoad()


        let backgroundImage = DefaultsHelper.desktopPasswordWindowBackgroundImage(includeDefault: false)

        if let backgroundImage = backgroundImage   {
            backgroundImageView.image = backgroundImage

            backgroundImageView.image=backgroundImage
            backgroundImageView.imageScaling = .scaleNone
        }

        

    }

}
