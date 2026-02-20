//
//  MainLoginWIndow.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 12/8/23.
//

import Cocoa

class MainLoginWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    //dragging cause crash. don't care about drag support so override
    //with empty
    override func drag(_ image: NSImage, at baseLocation: NSPoint, offset initialOffset: NSSize, event: NSEvent, pasteboard pboard: NSPasteboard, source sourceObj: Any, slideBack slideFlag: Bool) {
        return
    }
}
