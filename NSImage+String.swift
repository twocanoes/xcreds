//
//  UIImage+String.swift
//  XCreds
//
//  Created by Timothy Perfitt on 2/23/23.
//


import AppKit
extension NSImage {

    static func imageFromPathOrURL(pathURLString:String) -> NSImage? {

        var isFileURL = false
        //if a local path, remove prefix and make a path URL out of it.
        var pathURL:URL?
        if pathURLString.hasPrefix("file://") == true {
            isFileURL = true
            let pathOnly = pathURLString.dropFirst(7)
            pathURL = URL(fileURLWithPath: String(pathOnly))
        }
        else {
            //otherwise it is a https
            pathURL = URL(string: pathURLString)

        }

        //if we have a URL, try and load it
        if let pathURL = pathURL {
            TCSLogWithMark("PathURL: \(pathURL)")
            //create cache folder if needed

            let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .localDomainMask, true)

            let cacheDir = cachePath[0] as NSString
            TCSLogWithMark("cachedir: \(cacheDir)")

            let imageName = pathURL.lastPathComponent

            let cacheFolder  = cacheDir.appendingPathComponent("com.twocanoes.xcreds") as NSString

            let imageFullPath = cacheFolder.appendingPathComponent(imageName) as NSString
            TCSLogWithMark("imageFullPath: \(imageFullPath)")

            if FileManager.default.fileExists(atPath: cacheFolder as String) == false {
                TCSLogWithMark("cache folder doesn't exist, creating")

                try? FileManager.default.createDirectory(atPath: cacheFolder as String, withIntermediateDirectories: true)

            }

            TCSLogWithMark("loading image")

            //load image from URL
            let image = NSImage.init(contentsOf: pathURL)

            if pathURL.isFileURL==true{
                TCSLogWithMark("path URL is a file URL, returning what we have")

                return image
            }
            else {
                TCSLogWithMark("path URL is a not file URL")

            }

            //if a valid image, then use that and cache it.
            if let image = image {
                TCSLogWithMark("image is valid")

                let tiff = image.tiffRepresentation
                if let tiff = tiff {
                    TCSLogWithMark("created TIF")

                    let url = URL(fileURLWithPath:imageFullPath as String)
                    if FileManager.default.fileExists(atPath: imageFullPath as String) == true {
                        TCSLogWithMark("\(imageFullPath) exists")

                        do {
                            TCSLogWithMark("removing \(imageFullPath)")

                            try FileManager.default.removeItem(atPath: imageFullPath as String)
                        }
                        catch{
                            TCSLogWithMark("error: \(error)")
                        }
                    }
                    TCSLogWithMark("writing out  \(url)")

                    try? tiff.write(to:url )

                }
                TCSLogWithMark("returning image")

                return image
            }
            else {
                TCSLogWithMark("image is invalid")

            }

            TCSLogWithMark("getting cached image")

            //if we couldn't get the nsurl image, use the cached one
            let cachedImage = NSImage.init(contentsOfFile: imageFullPath as String)

            if let cachedImage = cachedImage {
                TCSLogWithMark("found image...returning")

                return cachedImage
            }
        }

        return nil
    }

}

