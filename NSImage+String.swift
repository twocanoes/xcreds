//
//  UIImage+String.swift
//  XCreds
//
//  Created by Timothy Perfitt on 2/23/23.
//


import AppKit
extension NSImage {

    static func imageFromPathOrURL(pathURLString:String) -> NSImage? {
        var pathURL:URL?
        if pathURLString.hasPrefix("file://") == true {
            let pathOnly = pathURLString.dropFirst(7)
            pathURL = URL(fileURLWithPath: String(pathOnly))
        }
        else {
            pathURL = URL(string: pathURLString)

        }

        if let pathURL = pathURL {

            let applicationSupportPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .localDomainMask, true)
            let cacheDir = applicationSupportPath[0] as NSString

            let imageName = pathURL.lastPathComponent
            let cacheFolder  = cacheDir.appendingPathComponent("com.twocanoes.xcreds") as NSString

            if FileManager.default.fileExists(atPath: cacheFolder as String) == false {

                try? FileManager.default.createDirectory(atPath: cacheFolder as String, withIntermediateDirectories: true)


            }
            let imageFullPath = cacheFolder.appendingPathComponent(imageName) as NSString
            if FileManager.default.fileExists(atPath: imageFullPath as String) == true {
                let image = NSImage.init(contentsOfFile: imageFullPath as String)
                return image

            }
            let image = NSImage.init(contentsOf: pathURL)

            if let image = image {
                let tiff = image.tiffRepresentation
                if let tiff = tiff {
                    let url = URL(fileURLWithPath:imageFullPath as String)
                    try? tiff.write(to:url )
                }
                return image
            }
        }

        return nil
    }

}
