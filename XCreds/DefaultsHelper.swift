//
//  DefaultsHelper.swift
//  XCreds
//
//  Created by Timothy Perfitt on 5/13/23.
//

import Cocoa

class DefaultsHelper: NSObject {

    static func backgroundImage() -> NSImage? {
        let coreServicesDefaultImagePathUrl: String = "file:///System/Library/CoreServices/DefaultDesktop.heic"
        TCSLogWithMark()
        if let imagePathURL = DefaultsOverride.standardOverride.string(forKey: PrefKeys.loginWindowBackgroundImageURL.rawValue), let image = NSImage.imageFromPathOrURL(pathURLString: imagePathURL){
            return image
        }
        // Try to use default desktop
        if let coreServicesDefaultImage = NSImage.imageFromPathOrURL(pathURLString: coreServicesDefaultImagePathUrl) {
            TCSLogWithMark("Using CoreServices Default Desktop image")
            return coreServicesDefaultImage
        }
       
        return nil
    }

    static func secondaryBackgroundImage(includeDefault:Bool=true) -> NSImage? {
        TCSLogWithMark()

        if let imagePathURL = DefaultsOverride.standardOverride.string(forKey: PrefKeys.loginWindowSecondaryMonitorsBackgroundImageURL.rawValue), let image = NSImage.imageFromPathOrURL(pathURLString: imagePathURL){
            return image
        }
        return backgroundImage()

    }

    static func desktopPasswordWindowBackgroundImage(includeDefault:Bool=true) -> NSImage? {
        TCSLogWithMark()
        if let imagePathURL = DefaultsOverride.standardOverride.string(forKey: PrefKeys.menuItemWindowBackgroundImageURL.rawValue), let image = NSImage.imageFromPathOrURL(pathURLString: imagePathURL){
            return image
        }
        else {

            let image = NSImage(named: NSImage.Name("xcredsmenuItemWindowBackgroundImage"))
            return image



        }
    }
}
