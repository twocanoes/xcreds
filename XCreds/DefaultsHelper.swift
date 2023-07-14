//
//  DefaultsHelper.swift
//  XCreds
//
//  Created by Timothy Perfitt on 5/13/23.
//

import Cocoa

class DefaultsHelper: NSObject {
    static func backgroundImage(includeDefault:Bool=true) -> NSImage? {
        TCSLogWithMark()
        if let imagePathURL = DefaultsOverride.standardOverride.string(forKey: PrefKeys.loginWindowBackgroundImageURL.rawValue), let image = NSImage.imageFromPathOrURL(pathURLString: imagePathURL){

            return image

        }
        else if includeDefault == true {
            let allBundles = Bundle.allBundles
            for currentBundle in allBundles {
                TCSLogWithMark(currentBundle.bundlePath)
                if currentBundle.bundlePath.contains("XCreds"), let imagePath = currentBundle.path(forResource: "DefaultBackground", ofType: "png") {
                    TCSLogWithMark()

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


                    break

                }
            }
        }
        return nil
    }

}
