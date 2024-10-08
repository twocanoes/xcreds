//
//  ShareMounter.swift
//  NoMAD
//
//  Created by Joel  on 8/29/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

// mad props to Kyle Crawshaw
// since much of this is cribbed from Share Mounter
//
//  ShareMounter.swift
//  ShareMounterCLI
//
//  Created by Joel Rennich on 7/10/19.
//  Copyright © 2019 Joel Rennich. All rights reserved.
//

import Foundation
import Cocoa
import NetFS

enum ShareKeys {
    static let homeMount = "HomeMountEnabled"
    static let mount = "Mount"
    static let shares = "Shares"
//    static let groups = "Groups"
    static let connectedOnly = "ConnectedOnly"
    static let options = "Options"
    static let name = "Name"
    static let autoMount = "AutoMount"
    static let localMount = "LocalMount"
    static let url = "URL"
    static let userShares = "UserShares"
    static let finderMount = "FinderMount"
    static let slowMount = "SlowMount"
    static let slowMountDelay = "SlowMountDelay"
    static let ignoreShareNames = "IgnoreShareNames"
}

enum mountStatus {
    case unmounted, toBeMounted, notInGroup, mounting, mounted, errorOnMount
}

struct share_info {
    var groups: [String]
    var originalURL: String
    var url: URL
    var name: String
    var options: [String]
    var connectedOnly: Bool
    var mountStatus: mountStatus?
    var localMount: String?
    var autoMount: Bool
    var reqID: AsyncRequestID?
    var attemptDate: Date?
    var localMountPoints: String?
    var isHome=false
}

struct mounting_shares_info {
    var share_url: URL
    var reqID: AsyncRequestID?
    var mount_time: Date
}

class ShareMounter {
    
    let defaults = UserDefaults.standard

    let fm = FileManager.default
    let ws = NSWorkspace.shared
    let sharePrefs = UserDefaults.standard

    var mountedShares = [URL]()
    var mountedOriginalShares = [String]()
    var mountedSharePaths = [URL:String]()
    
    var all_shares = [share_info]()
    var resolvedShares = [URL:String]()
    var now = Date()
    
    var tickets = false
    var userPrincipal = ""
    var connectedState = false
    
    var adUserRecord:ADUserRecord?
    let openOptionsDict : [String : Any] = [
        kNAUIOptionKey : kNAUIOptionNoUI,
        kNetFSUseGuestKey : false,
        kNetFSForceNewSessionKey : false,
        kNetFSUseAuthenticationInfoKey : true
    ]
    
    let mountOptionsDict : [String : Any] = [
        kNetFSSoftMountKey : true
    ]
    
    func getMounts() {
        
        var tempShares = [share_info]()
        
        guard let groups = adUserRecord?.groups else { return }

        if sharePrefs.bool(forKey: ShareKeys.homeMount)==true{

            TCSLogWithMark("Evaluating home share for automounts.")
            if let homePathRaw = adUserRecord?.homeDirectory {
                if var homePath = URL(string: "smb:" + homePathRaw) {

                    if defaults.bool(forKey: PrefKeys.homeAppendDomain.rawValue) {
                        if let domain = defaults.string(forKey: PrefKeys.aDDomain.rawValue),  let host = homePath.host {
                            var newHome = "smb://" + host + "." + domain
                            newHome += homePath.path
                            if let url = URL(string: newHome){
                                homePath = url
                            }
                        }
                    }

                    let homeShareGroups = sharePrefs.value(forKey: "HomeMountGroups") as? [String] ?? []
                    let homeShareOptions = sharePrefs.value(forKey: "HomeMountOptions") as? [String] ?? []

                    var currentShare = share_info(groups: homeShareGroups, originalURL: homePathRaw, url: homePath, name: defaults.string(forKey: PrefKeys.menuHomeDirectory.rawValue) ?? "Network Home", options: homeShareOptions, connectedOnly: true, mountStatus: .unmounted, localMount: nil, autoMount: true, reqID: nil, attemptDate: nil, localMountPoints: nil, isHome:true)

                    for share in all_shares {
                        if share.originalURL == currentShare.originalURL && (mountedOriginalShares.contains(share.originalURL) || share.mountStatus == .mounting) {
                            // share is still  mounting, so copy the share
                            if CommandLine.arguments.contains("-shares") {
                                print("Share is still mounting, using existing information")
                                print(share)
                            }
                            currentShare = share
                        }
                    }

                    tempShares.append(currentShare)
                    resolvedShares[currentShare.url] = homePathRaw

                }
            } else {
                TCSLogWithMark("Unable to get home share from preferences.")
            }
        } else {
            TCSLogWithMark("No home mount dictionary")
        }
        
        TCSLogWithMark("evaluating Shares")
        if let mountsRaw = sharePrefs.array(forKey: ShareKeys.shares) {
            
            if mountsRaw.count == 0 { 
                TCSLogWithMark("Mounts Empty")

                return
            }

            for mount in mountsRaw {
                
                guard mount is Dictionary<String, AnyObject> else { continue }
                let mountDict = mount as? [String:AnyObject] ?? [:]
                let shareGroups = mountDict["Groups"] as? [String] ?? []
                let shareLocalMount = mountDict["LocalMount"] as? String ?? ""
                let shareOptions = mountDict["Options"] as? [String] ?? []
                let shareConnectedOnly = mountDict["ConnectedOnly"] as? Bool ?? true
                if let shareName = mountDict["Name"] as? String,
                   let shareURL = mountDict["URL"] as? String,
                   let shareAutoMount = mountDict["AutoMount"] as? Bool,
                   let urlRaw = subVariables(shareURL) {

                    TCSLogWithMark("checking group membership for mounts")
                    let groupsArray = groups

                    if Set(groupsArray).intersection(Set(shareGroups)).count < 1 && shareGroups.count > 0 {
                        TCSLogWithMark("Not in the right group")
                        continue
                    }

                    guard let url = URL(string: urlRaw) else { continue }

                    var currentShare = share_info(groups: shareGroups, originalURL: shareURL, url: url, name: shareName, options: shareOptions, connectedOnly: shareConnectedOnly, mountStatus: .unmounted, localMount: shareLocalMount, autoMount: shareAutoMount, reqID: nil, attemptDate: nil, localMountPoints: nil)

                    if CommandLine.arguments.contains("-shares") {
                        print("Evaluating share: \(currentShare.originalURL)")
                    }

                    for share in all_shares {
                        if share.originalURL == currentShare.originalURL && (mountedOriginalShares.contains(share.originalURL) || share.mountStatus == .mounting) {
                            // share is still  mounting, so copy the share
                            if CommandLine.arguments.contains("-shares") {
                                print("Share is still mounting, using existing information")
                                print(share)
                            }
                            currentShare = share
                        } else {
                            if CommandLine.arguments.contains("-shares") {
                                print("Share: \(share.originalURL) doesn't match current share being evaluated: \(currentShare.originalURL), skipping ")
                            }
                        }
                    }
                    tempShares.append(currentShare)
                    resolvedShares[currentShare.url] = shareURL
                }
            }
        } else {
            TCSLogWithMark("No mount dictionary")
        }

        if CommandLine.arguments.contains("-shares") {
            print("***all_shares***")
            print(all_shares)
        }

        // do this atomically since other serivces depend on this list
        all_shares = tempShares
    }
    
    func getMountedShares() {

        // zero out the currently mounted shares
        mountedShares.removeAll()
        mountedSharePaths.removeAll()
        mountedOriginalShares.removeAll()
        
        guard let myShares = fm.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: FileManager.VolumeEnumerationOptions(rawValue: 0)) else { return }
        
        TCSLogWithMark("Currently mounted shares: \n" + String(describing: myShares))
        
        // we hardcode .timemachine in here b/c that will always fail on the getFileSystemInfo call
        var ignoreShares = [".timemachine", "/private/", "System/Volumes"]
        
        if let ignoreShareNamesTemp = sharePrefs.array(forKey: ShareKeys.ignoreShareNames) as? [String] {
            ignoreShares.append(contentsOf: ignoreShareNamesTemp)
        }
        
        for share in myShares {
            
            var myDes: NSString? = nil
            var myType: NSString? = nil
            
            // need to watch out for funky VM and TimeMachine shares
                      
            if ignoreShare(ignoreList: ignoreShares, share: share) {
                continue
            }
            
            guard ws.getFileSystemInfo(forPath: share.path, isRemovable: nil, isWritable: nil, isUnmountable: nil, description: &myDes, type: &myType) else {
                TCSLogWithMark("Get File info failed. Probably a synthetic Shared Folder.")
                // skip this share and move on to the next
                continue
            }
            
            guard let shareType = myType as String? else { continue }
            
            switch shareType {
            case "smbfs", "afpfs", "nfsfs", "webdavfs" :
                TCSLogWithMark("Volume: " + share.path + ", is a \(shareType.uppercased()) network volume.")
                guard let shareURL = getURL(share: share) else { continue }
                mountedShares.append(shareURL)
                mountedSharePaths[shareURL] = share.path
                mountedOriginalShares.append(resolvedShares[shareURL] ?? "NONE")
                
            default :
                // not a remote share
                TCSLogWithMark("Volume: " + share.path + ", is not a network volume.")
            }
        }
        TCSLogWithMark("Mounted shares: " + String(describing: mountedShares) )
    }
    
    func mountShares() {
        
        if all_shares.count == 0 {
            TCSLogWithMark("No shares to mount")
            return
        }
        
        for index in 0...(all_shares.count - 1) {
            
            if sharePrefs.bool(forKey: ShareKeys.homeMount)==false && all_shares[index].isHome==true {
                continue
            }

            TCSLogWithMark("Evaluating mount: " + all_shares[index].name)

            // TODO: ensure the URL is reachable before attempting to mount
            
            // loop through all the reasons to not mount this share
            
            if all_shares[index].mountStatus == .mounted || mountedShares.contains(all_shares[index].url) {
                // already mounted
                
                if  mountedShares.contains(all_shares[index].url) {
                    all_shares[index].mountStatus = .mounted
                }
                
                TCSLogWithMark("Skipping mount because it's already mounted.")
                continue
            } else if mountedOriginalShares.contains(all_shares[index].originalURL) {
                
                all_shares[index].mountStatus = .mounted
                
                TCSLogWithMark("Skipping mount because share is still mounted from a previous variable substitution.")
                continue
            } else if all_shares[index].mountStatus == .mounting {
                TCSLogWithMark("Skipping mount because share is still in the process of being mounted - kick back on a natural for a bit.")
                if let mountInterval = (all_shares[index].attemptDate?.timeIntervalSinceNow) {
                    if abs(mountInterval) > 5 * 60 {
                        all_shares[index].mountStatus = .toBeMounted
                    }
                }
                continue
            } else {
                all_shares[index].mountStatus = .unmounted
            }
            
            if !all_shares[index].autoMount {
                // not to be automounted
                TCSLogWithMark("Skipping mount because it's not set to Automount.")
                continue
            }
            
            if all_shares[index].connectedOnly && !connectedState {
                // not connected
                TCSLogWithMark("Skipping mount because we're not connected.")
                continue
            }
            
            if !tickets {
                // skipping b/c we don't have kerb tickets
                TCSLogWithMark("Skipping mount because we don't have tickets")
                continue
            }
            
            if (all_shares[index].mountStatus != .errorOnMount) && (all_shares[index].mountStatus != .mounting) {
                
                let openOptions = openOptionsDict
                var mountOptions = mountOptionsDict
                
                if all_shares[index].options.count > 0 {
                    let mountFlagValue = parseOptions(options: all_shares[index].options)
                    TCSLogWithMark("Mount options: (mountFlagValue)")
                    mountOptions[kNetFSMountFlagsKey] = mountFlagValue
                }
                
                var requestID: AsyncRequestID?
                let queue = DispatchQueue.main
                
                TCSLogWithMark("Attempting to mount: " + all_shares[index].url.absoluteString)
                
                if sharePrefs.bool(forKey: ShareKeys.slowMount)  {
                    let delay: useconds_t
                    delay = useconds_t(1000 * (sharePrefs.integer(forKey: ShareKeys.slowMountDelay)))
                    usleep(delay)
                    TCSLogWithMark("Delaying next Mount by " + String(delay/1000) + " milliseconds since SlowMount is set.")
                }
                                
                if sharePrefs.bool(forKey: ShareKeys.finderMount) {

                    TCSLogWithMark("Mounting share via Finder")
                    _ = cliTask("/usr/bin/open \(all_shares[index].url.absoluteString)")
                    all_shares[index].mountStatus = .mounted
                    all_shares[index].reqID = nil
                    all_shares[index].attemptDate = Date()
                    
                    // going for next share
                    continue
                }
                
                _ = NetFSMountURLAsync(all_shares[index].url as CFURL?,
                                       nil,
                                       userPrincipal as CFString?,
                                       nil,
                                       (openOptions as! CFMutableDictionary),
                                       (mountOptions as! CFMutableDictionary),
                                       &requestID,
                                       queue) {(stat: Int32, requestID: AsyncRequestID?, mountpoints: CFArray?) -> Void in
                    TCSLogWithMark("Request ID: \(requestID!)")
                    for index in 0...(self.all_shares.count - 1) {
                        if self.all_shares[index].reqID == requestID {
                            if stat == 0 {
                                TCSLogWithMark("Mounted share: " + self.all_shares[index].name)
                                self.all_shares[index].mountStatus = .mounted
                                self.all_shares[index].reqID = nil
                                let mounts = mountpoints as! Array<String>
                                self.all_shares[index].localMountPoints = mounts[0]
                            } else {
                                TCSLogWithMark("Error on mounting share: " + self.all_shares[index].name)
                                self.all_shares[index].mountStatus = .errorOnMount
                                self.all_shares[index].reqID = nil
                            }
                        }
                    }
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "menu.nomad.NoMAD.updateNow"), object: self)
                    //                                        self.mountShares()

                }
                
                all_shares[index].mountStatus = .mounting
                all_shares[index].reqID = requestID
                all_shares[index].attemptDate = Date()
                
            } else {
                // clean up any errored mounts
                let mountInterval = (all_shares[index].attemptDate?.timeIntervalSinceNow)!
                if abs(mountInterval) > 5 * 60 {
                    all_shares[index].mountStatus = .toBeMounted
                }
            }
        }
    }
    
    func syncMountShare(_ serverAddress: URL, options: [String], open: Bool=false) {
        
        let openOptions = openOptionsDict
        var mountOptions = mountOptionsDict
        
        if options.count > 0 {
            let mountFlagValue = parseOptions(options: options)
            TCSLogWithMark("Mount options: (mountFlagValue)")
            mountOptions[kNetFSMountFlagsKey] = mountFlagValue
        }
        
        var mountArray: Unmanaged<CFArray>? = nil
        
        let myResult = NetFSMountURLSync(serverAddress as CFURL?, nil, nil, nil, (openOptions as! CFMutableDictionary), (mountOptions as! CFMutableDictionary), &mountArray)
        TCSLogWithMark(myResult.description)
        
        if let mountPoint = mountArray!.takeRetainedValue() as? [String] {
            if myResult == 0 && open {
                NSWorkspace.shared.open(URL(fileURLWithPath: mountPoint[0], isDirectory: true))
            }
        }
    }
    
    func asyncMountShare(_ serverAddress: URL, options: [String], open: Bool=false) {
        
        let openOptions = openOptionsDict
        var mountOptions = mountOptionsDict
        
        if options.count > 0 {
            let mountFlagValue = parseOptions(options: options)
            TCSLogWithMark("Mount options: (mountFlagValue)")
            mountOptions[kNetFSMountFlagsKey] = mountFlagValue
        }
        
        var requestID: AsyncRequestID? = nil
        let queue = DispatchQueue.main
        
        TCSLogWithMark("Attempting to mount: " + String(describing: serverAddress))
        
        let _ = NetFSMountURLAsync(serverAddress as CFURL?,
                                   nil,
                                   userPrincipal as CFString?,
                                   nil,
                                   (openOptions as! CFMutableDictionary),
                                   (mountOptions as! CFMutableDictionary),
                                   &requestID,
                                   queue)
        {(stat:Int32, requestID:AsyncRequestID?, mountpoints:CFArray?) -> Void in
            
            if stat == 0 {
                TCSLogWithMark("Mounted share: " + String(describing: serverAddress))
                
                if let mountPoint = (mountpoints! as! [String]).first {
                    NSWorkspace.shared.open(URL(fileURLWithPath: mountPoint, isDirectory: true))
                }
            } else {
                TCSLogWithMark("Error mounting share: " + String(describing: serverAddress))
            }
        }
    }
    
    ///MARK: Helper functions
    
    private func getURL(share: URL) -> URL? {
        let shareURLUnmanaged = NetFSCopyURLForRemountingVolume(share as CFURL)
        guard let myShare = shareURLUnmanaged else {
            return nil
        }
        
        let shareURL = myShare.takeUnretainedValue() as URL
        return URL(string: (shareURL.scheme! + "://" + shareURL.host! + shareURL.path.safeURLPath()!))!
    }
    
    fileprivate func subVariables(_ url: String) -> String? {
        // TODO: get e-mail address as a variable
        var createdURL = url
        
        guard let domain = adUserRecord?.domain,
              let fullName = adUserRecord?.fullName.safeURLPath(),
            let serial = getSerial().safeURLPath(),
              let shortName = adUserRecord?.shortName
            else {
                return nil
        }
        // filter out any blank spaces too
        
        createdURL = createdURL.replacingOccurrences(of: " ", with: "%20")
        createdURL = createdURL.replacingOccurrences(of: "<<domain>>", with: domain)
        createdURL = createdURL.replacingOccurrences(of: "<<fullname>>", with: fullName)
        createdURL = createdURL.replacingOccurrences(of: "<<serial>>", with: serial)
        createdURL = createdURL.replacingOccurrences(of: "<<shortname>>", with: shortName)
        
        let currentDC = defaults.string(forKey: PrefKeys.aDDomainController.rawValue) ?? "NONE"
        createdURL = createdURL.replacingOccurrences(of: "<<domaincontroller>>", with: currentDC)
        
        return createdURL
    }
    
    fileprivate func parseOptions(options:  [String] ) -> Int {
        var mountFlagValue = 0
        for option in options {
            switch option {
            case "MNT_RDONLY"            : mountFlagValue += 0x00000001
            case "MNT_SYNCHRONOUS"       : mountFlagValue += 0x00000002
            case "MNT_NOEXEC"            : mountFlagValue += 0x00000004
            case "MNT_NOSUID"            : mountFlagValue += 0x00000008
            case "MNT_NODEV"             : mountFlagValue += 0x00000010
            case "MNT_UNION"             : mountFlagValue += 0x00000020
            case "MNT_ASYNC"             : mountFlagValue += 0x00000040
            case "MNT_CPROTECT"          : mountFlagValue += 0x00000080
            case "MNT_EXPORTED"          : mountFlagValue += 0x00000100
            case "MNT_QUARANTINE"        : mountFlagValue += 0x00000400
            case "MNT_LOCAL"             : mountFlagValue += 0x00001000
            case "MNT_QUOTA"             : mountFlagValue += 0x00002000
            case "MNT_ROOTFS"            : mountFlagValue += 0x00004000
            case "MNT_DOVOLFS"           : mountFlagValue += 0x00008000
            case "MNT_DONTBROWSE"        : mountFlagValue += 0x00100000
            case "MNT_IGNORE_OWNERSHIP"  : mountFlagValue += 0x00200000
            case "MNT_AUTOMOUNTED"       : mountFlagValue += 0x00400000
            case "MNT_JOURNALED"         : mountFlagValue += 0x00800000
            case "MNT_NOUSERXATTR"       : mountFlagValue += 0x01000000
            case "MNT_DEFWRITE"          : mountFlagValue += 0x02000000
            case "MNT_MULTILABEL"        : mountFlagValue += 0x04000000
            case "MNT_NOATIME"           : mountFlagValue += 0x10000000
            default                      : mountFlagValue += 0
            }
        }
        return mountFlagValue
    }
    
    fileprivate func ignoreShare(ignoreList: [String], share: URL) -> Bool {
    
        for ignoreName in ignoreList {
            if share.path.containsIgnoringCase(ignoreName) {
                myLogger.logit(.info, message: "Ignoring share: \(share.path) because of share name")
                return true
            }
        }
        return false
    }
}
