//
//  ShareMounter.swift
//  NoMAD
//
//  Created by Joel Rennich on 8/29/16.
//  Copyright © 2016 Trusource Labs. All rights reserved.
//

// mad props to Kyle Crawshaw
// since much of this is cribbed from Share Mounter

import Foundation
import NetFS

struct share_info {
    var groups: [String]
    var share_url: String
    var title: String
}

class ShareMounter {

    var all_shares = [share_info]()
    let ws = NSWorkspace.init()
    var prefs: [String]

    init() {
        // read in the preference files


        if UserDefaults.standard.bool(forKey: PrefKeys.showHome.rawValue) {
            //NSLog("Looking for ShareMounter files")
            //prefs = try! ["/Library/Preferences/ShareMounter.plist", NSHomeDirectory() + "/Library/Preferences/ShareMounter.plist"]
            /*
             do {
             try! getShares()
             }
             } else {
             prefs = [""]
             */
        }
        prefs = [""]
    }

    func mount() {

        let myGroups = UserDefaults.standard.array(forKey: PrefKeys.groups.rawValue)

        for share in all_shares {
            for group in myGroups! {
                if share.groups.contains(group as! String) {
                    // time to mount
                    NSLog("Attempting to mount: " + share.share_url)
                    asyncMountShare(share.share_url)
                    break
                }
            }
        }
    }

    func getShares() {
        for place in prefs {
            let myDictionary = NSDictionary.init(contentsOfFile: place)

            if myDictionary != nil {
                let shares = (myDictionary?.object(forKey: "network_shares"))! as! [AnyObject]

                for i in shares {
                    let currentShare = share_info(groups: i.object(forKey: "groups")! as! Array, share_url: i.object(forKey: "share_url")! as! String, title: i.object(forKey: "title")! as! String)
                    all_shares.append(currentShare)
                }
            }
        }
    }

    func openOptionsDict() -> CFMutableDictionary {
        let dict = NSMutableDictionary()
        dict[kNAUIOptionKey] = kNAUIOptionNoUI
        dict[kNetFSUseGuestKey] = true
        return dict
    }

    func mountOptionsDict() -> CFMutableDictionary {
        let dict = NSMutableDictionary()
        //dict[kNetFSMountFlagsKey] = Int(MNT_DONTBROWSE)
        return dict
    }

    func asyncMountShare(_ serverAddress: String) {

        let escapedAddress = serverAddress.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let shareAddress = URL(string: escapedAddress!)!

        // TODO: ensure the URL is reachable before attempting to mount

        //let open_options : CFMutableDictionary = openOptionsDict()
        let mount_options : CFMutableDictionary = mountOptionsDict()

        var requestID: AsyncRequestID? = nil
        let queue = DispatchQueue.main

        if let userPrinc = UserDefaults.standard.string(forKey: PrefKeys.userPrincipal.rawValue){
            NetFSMountURLAsync(shareAddress as CFURL,
                               nil,
                               userPrinc as CFString,
                               nil,
                               nil,
                               mount_options,
                               &requestID,
                               queue)
            {(stat:Int32, requestID:AsyncRequestID?, mountpoints:CFArray?) -> Void in
                if let mountpoints = mountpoints as? Array<String>{
                    myLogger.logit(.base, message: "Mounted \(mountpoints)")
                }
            }
        }



        func getNetworkShares() {
            let fm = FileManager.default

            let myShares = fm.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: FileManager.VolumeEnumerationOptions.skipHiddenVolumes)

            for share in myShares! {

                var myDes: NSString? = nil
                var myType: NSString? = nil

                ws.getFileSystemInfo(forPath: share.path, isRemovable: nil, isWritable: nil, isUnmountable: nil, description: &myDes, type: &myType)
                print(myType!)
                if myType! == "smbfs" {
                    print("Volume: " + share.path + " is an SMB network volume.")
                }
            }
        }
    }
}
