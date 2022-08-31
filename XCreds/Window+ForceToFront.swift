//
//  Window+ForceToFront.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

extension NSWindow {
    @objc func forceToFrontAndFocus(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        TCSLogWithMark("forcing front")
        self.makeKeyAndOrderFront(sender);
    }
}
