//
//  DefaultsHelper.swift
//  XCreds
//
//  Created by Timothy Perfitt on 5/13/23.
//

import Cocoa

class DefaultsHelper: NSObject {
    static func backgroundImage(includeDefault:Bool=true) -> NSImage? {
        if let imagePathURL = UserDefaults.standard.string(forKey: PrefKeys.loginWindowBackgroundImageURL.rawValue), let image = NSImage.imageFromPathOrURL(pathURLString: imagePathURL){

            return image

        }
        else if includeDefault == true {
            let allBundles = Bundle.allBundles
            for currentBundle in allBundles {
                TCSLogWithMark(currentBundle.bundlePath)
                if currentBundle.bundlePath.contains("XCreds"), let imagePath = currentBundle.path(forResource: "DefaultBackground", ofType: "png") {
                    TCSLogWithMark()

                    let image = NSImage.init(byReferencingFile: imagePath)

                    if let image = image {
                        return image
                    }
                    break

                }
            }
        }
        return nil
    }

}
