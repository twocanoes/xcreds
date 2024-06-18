//
//  UIImage+String.swift
//  XCreds
//
//  Created by Timothy Perfitt on 2/23/23.
//


import AppKit
extension NSImage {

    static func imageFromPathOrURL(pathURLString:String) -> NSImage? {

        //if a local path, remove prefix and make a path URL out of it.
        var pathURL:URL?
        if pathURLString.hasPrefix("file://") == true {
            let pathOnly = pathURLString.dropFirst(7)
            pathURL = URL(fileURLWithPath: String(pathOnly))
        }
        else {
            //otherwise it is a https
            pathURL = URL(string: pathURLString)

        }

        //if we have a URL, try and load it
        if let pathURL = pathURL {
            //create cache folder if needed

            let applicationSupportPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .localDomainMask, true)
            let cacheDir = applicationSupportPath[0] as NSString

            let imageName = pathURL.lastPathComponent

            let cacheFolder  = cacheDir.appendingPathComponent("com.twocanoes.xcreds") as NSString

            let imageFullPath = cacheFolder.appendingPathComponent(imageName) as NSString

            if FileManager.default.fileExists(atPath: cacheFolder as String) == false {

                try? FileManager.default.createDirectory(atPath: cacheFolder as String, withIntermediateDirectories: true)

            }

            //load image from URL
            let image = NSImage.init(contentsOf: pathURL)

            //if a valid image, then use that and cache it.
            if let image = image {
                let tiff = image.tiffRepresentation
                if let tiff = tiff {
                    let url = URL(fileURLWithPath:imageFullPath as String)
                    if FileManager.default.fileExists(atPath: imageFullPath as String) == true {
                        do {
                            try FileManager.default.removeItem(atPath: imageFullPath as String)
                        }
                        catch{
                            TCSLogWithMark("error: \(error)")
                        }
                    }

                    try? tiff.write(to:url )
                }
                return image
            }

            //if we couldn't get the nsurl image, use the cached one
            let cachedImage = NSImage.init(contentsOfFile: imageFullPath as String)

            if let cachedImage = cachedImage {
                return cachedImage
            }
        }

        return nil
    }

}

