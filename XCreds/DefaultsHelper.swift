//
//  DefaultsHelper.swift
//  XCreds
//
//  Created by Timothy Perfitt on 5/13/23.
//

import Cocoa

class DefaultsHelper: NSObject {

    static func backgroundImage(includeDefault:Bool=true) -> NSImage? {
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
        if includeDefault == true {

            let bundle = Bundle.findBundleWithName(name: "XCreds")

            guard let bundle = bundle else {
                return nil
            }

            TCSLogWithMark()
            if let imagePath = bundle.path(forResource: "DefaultBackground", ofType: "png") {

                if FileManager.default.fileExists(atPath: imagePath){
                    let image = NSImage.init(byReferencingFile: imagePath)
                    TCSLogWithMark()

                    if let image = image {
                        return image
                    }
                }
                else {
                    TCSLogWithMark("No image found at \(imagePath)")
                }

                TCSLogWithMark()
            }

        }
        return nil
    }

    static func secondaryBackgroundImage(includeDefault:Bool=true) -> NSImage? {
        TCSLogWithMark()

        if let imagePathURL = DefaultsOverride.standardOverride.string(forKey: PrefKeys.loginWindowSecondaryMonitorsBackgroundImageURL.rawValue), let image = NSImage.imageFromPathOrURL(pathURLString: imagePathURL){
            return image
        }
        return backgroundImage(includeDefault: includeDefault)

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
