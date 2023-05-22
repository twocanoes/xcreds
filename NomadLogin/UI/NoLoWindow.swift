//
//  NoLoWindow.swift
//  NoMADLoginAD
//
//  Created by Joseph Rafferty on 10/24/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation
import Cocoa


class NoLoWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: .buffered, defer: false)
    }
    
    override var canBecomeKey: Bool {
        get {
            return true
        }
    }
    
    override var canBecomeMain: Bool {
        get {
            return true
        }
    }
}
