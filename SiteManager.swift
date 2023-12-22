//
//  SiteManager.swift
//  NoMAD
//
//  Created by Joel Rennich on 9/11/17.
//  Copyright © 2018 Orchard & Grove Inc. All rights reserved.
//

import Foundation
import SystemConfiguration
//import NoMADPRIVATE

// singleton for the class

let siteManager = SiteManager()

var updatePending = false
var updateTimer: Timer? = nil

// simple class to use as a global site manager

class SiteManager {
    
    // variables
    
    var sites = [String:[NoMADLDAPServer]]()
    
    // this seems silly to set a notification to notify internally to clearSites... but here goes
    
    let changed: SCDynamicStoreCallBack = { dynamicStore, _, _ in
        
        // TODO: throttle too many lookups too quickly
        
        print("Network change")
        let updateNotification = Notification(name: Notification.Name(rawValue: "menu.nomad.NoMAD-ADAuth.updateNow"))
        NotificationQueue.default.enqueue(updateNotification, postingStyle: .now)
        
    }
    
    func checkNetwork() {
        var dynamicContext = SCDynamicStoreContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let dcAddress = withUnsafeMutablePointer(to: &dynamicContext, {UnsafeMutablePointer<SCDynamicStoreContext>($0)})
        
        if let dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, "menu.nomad.NoMAD.networknotification" as CFString, changed, dcAddress) {
            let keysArray = ["State:/Network/Global/IPv4" as CFString, "State:/Network/Global/IPv6"] as CFArray
            SCDynamicStoreSetNotificationKeys(dynamicStore, nil, keysArray)
            let loop = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynamicStore, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, .defaultMode)
        }
        
        // register for notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(clearSites), name: NSNotification.Name(rawValue: "menu.nomad.NoMAD-ADAuth.updateNow"), object: nil)
    }
    
    @objc func clearSites() {
        
        // removes all sites
        
        sites.removeAll()
    }
    
    // listen for network changes
}
