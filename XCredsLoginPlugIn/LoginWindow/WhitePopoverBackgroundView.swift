//
//  WhitePopoverBackgroundView.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 6/8/24.
//

import Cocoa

class WhitePopoverBackgroundView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.white.set()
        bounds.fill()
        // Drawing code here.
    }
    
}
