//
//  NSBundle+FindBundlePath.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 12/8/23.
//

import Foundation

extension Bundle {

    static func findBundleWithName(name: String) -> Bundle? {
        let allBundles = self.allBundles
        for currentBundle in allBundles {
            if currentBundle.bundlePath.contains(name) {

                let bundle = Bundle(path: currentBundle.bundlePath)
                return bundle

            }
        }

        return nil
    }

}
