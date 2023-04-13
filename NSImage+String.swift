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
            let image = NSImage.init(contentsOf: pathURL)

            if let image = image {
                return image
//                image.size=screenRect.size
//                backgroundImageView.image = image
            }
        }

        return nil
    }

}
