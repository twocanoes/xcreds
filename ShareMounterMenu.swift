//
//  ShareMounterMenu.swift
//  NoMAD
//
//  Created by Joel Rennich on 8/12/17.
//  Copyright © 2017 Orchard & Grove Inc. All rights reserved.
//

import Foundation

let shareMounterMenu = ShareMounterMenu()
let shareMounterQueue = DispatchQueue(label: "menu.nomad.NoMAD.shareMounting", attributes: [])

// class to build the share mount menu and accept clicks

@objc class ShareMounterMenu: NSObject {

    let defaults = UserDefaults.standard

    var shareMounter:ShareMounter?
    @objc var worksWhenModal = true
    @objc let myShareMenu = NSMenu()
    
    var sharePrefs = UserDefaults.standard

    @objc func updateShares(connected: Bool=false, tickets: Bool=false) {
        
        guard let kerbUser = PasswordUtils().kerberosPrincipalFromCurrentLoggedInUser() else {

         return
        }

        shareMounterQueue.sync(execute: {
            self.shareMounter?.connectedState = connected
            self.shareMounter?.tickets = tickets
            self.shareMounter?.userPrincipal = kerbUser
            self.shareMounter?.getMountedShares()
            self.shareMounter?.getMounts()
            self.shareMounter?.mountShares()
        })

    }
    
    @objc func buildMenu(connected: Bool=false) -> NSMenu {
        
        guard let shareMounter = shareMounter else {
            return NSMenu()

        }
//        if sharePrefs.integer(forKey: "Version") != 1 {
//            return NSMenu.init()
//        }
        
        // check for an actual ticket
        
        klistUtil.klist()
        
//        if !klistUtil.state {
//            TCSLogWithMark("No valid ticket, not attempting to mount shares.")
//            
////            NotificationQueue.default.enqueue(updateNotification, postingStyle: .now)
//
//            return NSMenu.init()
//        }
//        guard let user = try? PasswordUtils.getLocalRecord(getConsoleUser()) else {
//
//            return NSMenu()
//        }
//        if defaults.object(forKey: PrefKeys.userShortName.rawValue) == nil {
//            TCSLogWithMark("No user name, not attempting to mount shares.")
//            return NSMenu.init()
//        }
        
        if shareMounter.all_shares.count > 0 {
            // Menu Items and Menu
            
            myShareMenu.removeAllItems()
            
            if CommandLine.arguments.contains("-shares") {
                print("***Building Share Menu***")
                print(shareMounter.all_shares)
            }
            
            for share in shareMounter.all_shares {
                let myItem = NSMenuItem()
                myItem.title = share.name
                myItem.target = self

                if share.connectedOnly == true  && connected == false {
                    myItem.target = nil
                }
                myItem.action = #selector(openShareFromMenu(_:))
                myItem.toolTip = String(describing: share.url)
                if share.mountStatus == .mounted {
                    myItem.isEnabled = true
//                    myItem.state = NSControl.StateValue(rawValue: 1)
                } else if share.mountStatus == .mounting {
                    myItem.isEnabled = false
//                    myItem.state = NSControl.StateValue(rawValue: 0)
                } else if share.mountStatus == .unmounted {
                    myItem.isEnabled = true
//                    myItem.state = NSControl.StateValue(rawValue: 0)
                } else if share.mountStatus == .errorOnMount {
                    myItem.isEnabled = false
//                    myItem.state = NSControl.StateValue(rawValue: 0)
                }

                myShareMenu.addItem(myItem)
            }
        }
        
        if CommandLine.arguments.contains("-shares") {
            print("***Share Menu***")
            print(myShareMenu)
        }
        
        return myShareMenu
    }
    
    @IBAction func openShareFromMenu(_ sender: AnyObject) {
        guard let shareMounter = shareMounter else {
            return
        }
        for share in shareMounter.all_shares {
            if share.name == sender.title {
                if share.mountStatus != .mounted {
                    TCSLogWithMark("Mounting share: " + String(describing: share.url))
                    
                    //myShareMounter.asyncMountShare(share.url, options: share.options, open: true)
                    //_ = cliTask("open " + DFSResolver.checkAndReplace(url: share.url))
                    _ = cliTask("open " + share.url.absoluteString.safeURLPath()!)
                } else if share.mountStatus == .mounted {
                    // open up the local shares
                    
                    // cliTask(“open ” + DFSResolver.checkAndReplace(url: share.url))
                    
                    if share.localMountPoints != nil {
                        NSWorkspace.shared.open(URL(fileURLWithPath: share.localMountPoints!, isDirectory: true))
                    } else {
                        _ = cliTask("open " + share.url.absoluteString.safeURLPath()!)
                    }
                }
            }
        }
    updateShares()
    }
    
    // utility functions
    
    @objc func sharesAvilable() -> Bool {
        if myShareMenu.items.count == 0 {
            return false
        } else {
            return true
        }
    }
}
