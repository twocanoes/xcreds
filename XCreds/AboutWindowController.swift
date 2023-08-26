//
//  AboutWindowController.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class AboutWindowController: NSWindowController {


    @IBOutlet weak var aboutTextView:NSTextView!
    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("AboutWindow")
    }

     override func awakeFromNib() {

         let infoPlist = Bundle.main.infoDictionary
         if let infoPlist = infoPlist {
             let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

             let build = infoPlist["CFBundleVersion"] as? String

             let historyPath = Bundle.main.path(forResource: "History", ofType: "md")
             let creditsPath = Bundle.main.path(forResource: "Credits", ofType: "txt")
             if let historyPath = historyPath, let historyString = try? String(contentsOfFile: historyPath, encoding: .utf8), let creditsPath = creditsPath ,let creditsString = try? String(contentsOfFile: creditsPath, encoding: .utf8), let build = build, let appVersion = appVersion  {

                 aboutTextView.string="XCreds\nCopyright Twocanoes Software, Inc.\nVersion \(appVersion) (\(build))\n\n"+creditsString + historyString

             }
         }

    }

}
