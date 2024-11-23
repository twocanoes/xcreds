//
//  EnableFDE.swift
//  NoMADLoginAD
//
//  Created by Admin on 2/5/18.
//  Copyright © 2018 NoMAD. All rights reserved.
//

import Cocoa


class XCredsEnableFDE : XCredsBaseMechanism {
    let enableFDELog = "enableFDELog"
    // basic mech to enable FileVault
    // needs to be a separate mech b/c it needs to run after loginwindow:done
    
    @objc override  func run() {
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ EnableFDE mech starting mech starting ~~~~~~~~~~~~~~~~~~~")

        // FileVault
        
        if getManagedPreference(key: .EnableFDE) as? Bool == true {
            // check to see if we're already FileVaulted
            
            if isFdeEnabled() {
                
                os_log("Checking to see if we should rekey", log: enableFDELog, type: .default)
                
                if getManagedPreference(key: .EnableFDERekey) as? Bool ?? false {
                    rekey()
                }
                
                os_log("FileVault is already enabled, skipping mechanism.", log: enableFDELog, type: .debug)
                
            } else {
                enableFDE()
            }
        }
        
        // Always let login through
        
        let _ = allowLogin()
    }
    
    fileprivate func rekey() {
        
        
        os_log("Rekeying FileVault", log: enableFDELog, type: .default)
        
        let userArgs = [
            "Username" : xcredsUser ?? "",
            "Password" : xcredsPass ?? "",
            ]
        
        var userInfo : Data
        
        do {
            userInfo = try PropertyListSerialization.data(fromPropertyList: userArgs,
                                                          format: PropertyListSerialization.PropertyListFormat.xml,
                                                          options: 0)
        } catch {
            os_log("Unable to create fdesetup arguments.", log: enableFDELog, type: .error)
            return
        }
        
        let inPipe = Pipe.init()
        let outPipe = Pipe.init()
        let errorPipe = Pipe.init()
        
        let task = Process.init()
        task.launchPath = "/usr/bin/fdesetup"
        task.arguments = ["changerecovery", "-outputplist", "-inputplist"]
        
        task.standardInput = inPipe
        task.standardOutput = outPipe
        task.standardError = errorPipe
        task.launch()
        inPipe.fileHandleForWriting.write(userInfo)
        inPipe.fileHandleForWriting.closeFile()
        task.waitUntilExit()
        
        let outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
        outPipe.fileHandleForReading.closeFile()
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorMessage = String(data: errorData, encoding: .utf8)
        errorPipe.fileHandleForReading.closeFile()
        
        let output = NSString(data: outputData, encoding: String.Encoding.utf8.rawValue)! as String
            
        // write out the PRK if asked to
        
        if getManagedPreference(key: .EnableFDERecoveryKey) as? Bool == true {
            
            var recoveryPath = "/var/db/FDE"
            
            if let newPath = getManagedPreference(key: .EnableFDERecoveryKeyPath) as? String {
                recoveryPath = newPath
            }
            
            let fm = FileManager.default
            
            if !fm.fileExists(atPath: recoveryPath, isDirectory: nil) {
                do {
                    os_log("Creating folder for recovery key storage.", log: enableFDELog)
                    try fm.createDirectory(atPath: recoveryPath, withIntermediateDirectories: true, attributes: [FileAttributeKey.posixPermissions : 0o750])
                } catch {
                    os_log("Unable to create file path for PRK, defaulting to /var/db/", log: enableFDELog)
                    
                    // reset recovery path to something we know will exist
                    
                    recoveryPath = "/var/db/"
                }
            }
            
            recoveryPath += "/FDESetup.plist"
            
            do {
                os_log("Attempting to write key to: %{public}@", log: enableFDELog, type: .default, recoveryPath)
                try output.write(toFile: recoveryPath, atomically: true, encoding: String.Encoding.ascii)
            } catch {
                os_log("Unable to finish fdesetup: %{public}@", log: enableFDELog, type: .error, errorMessage ?? "Unkown error")
            }
        }
        
    }
    
    fileprivate func enableFDE() {
        
        // check to see if boot volume is AFPS, otherwise do nothing
        
        if volumeAPFS() {
            
            // enable FDE on volume by using fdesetup
            
            os_log("Enabling FileVault", log: enableFDELog, type: .default)
            
            let userArgs = [
                "Username" : xcredsUser ?? "",
                "Password" : xcredsPass ?? "",
                ]
            
            var userInfo : Data
            
            do {
                userInfo = try PropertyListSerialization.data(fromPropertyList: userArgs,
                                                              format: PropertyListSerialization.PropertyListFormat.xml,
                                                              options: 0)
            } catch {
                os_log("Unable to create fdesetup arguments.", log: enableFDELog, type: .error)
                return
            }
            
            let inPipe = Pipe.init()
            let outPipe = Pipe.init()
            let errorPipe = Pipe.init()
            
            let task = Process.init()
            task.launchPath = "/usr/bin/fdesetup"
            task.arguments = ["enable", "-outputplist", "-inputplist"]
            
            task.standardInput = inPipe
            task.standardOutput = outPipe
            task.standardError = errorPipe
            task.launch()
            inPipe.fileHandleForWriting.write(userInfo)
            inPipe.fileHandleForWriting.closeFile()
            task.waitUntilExit()
            
            let outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
            outPipe.fileHandleForReading.closeFile()
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8)
            errorPipe.fileHandleForReading.closeFile()
            
            let output = NSString(data: outputData, encoding: String.Encoding.utf8.rawValue)! as String
                    
            // write out the PRK if asked to
            
            // write out the PRK if asked to
            
            if getManagedPreference(key: .EnableFDERecoveryKey) as? Bool == true {
                
                var recoveryPath = "/var/db/FDE"
                
                if let newPath = getManagedPreference(key: .EnableFDERecoveryKeyPath) as? String {
                    recoveryPath = newPath
                }
                
                let fm = FileManager.default
                
                if !fm.fileExists(atPath: recoveryPath, isDirectory: nil) {
                    do {
                        os_log("Creating folder for recovery key storage.", log: enableFDELog)
                        try fm.createDirectory(atPath: recoveryPath, withIntermediateDirectories: true, attributes: [FileAttributeKey.posixPermissions : 0o750])
                    } catch {
                        os_log("Unable to create file path for PRK, defaulting to /var/db/", log: enableFDELog)
                        
                        // reset recovery path to something we know will exist
                        
                        recoveryPath = "/var/db/"
                    }
                }
                
                recoveryPath += "/FDESetup.plist"
                
                do {
                    os_log("Attempting to write key to: %{public}@", log: enableFDELog, type: .default, recoveryPath)
                    try output.write(toFile: recoveryPath, atomically: true, encoding: String.Encoding.ascii)
                } catch {
                    os_log("Unable to finish fdesetup: %{public}@", log: enableFDELog, type: .error, errorMessage ?? "Unkown error")
                }
            }
        } else {
            os_log("Boot volume is not APFS, skipping FDE.", log: enableFDELog, type: .debug)
        }
    }
    
    fileprivate func volumeAPFS() -> Bool {
        
        // get shared workspace manager
        
        let ws = NSWorkspace.shared
        
        var description: NSString?
        var type: NSString?
        
        let err = ws.getFileSystemInfo(forPath: "/", isRemovable: nil, isWritable: nil, isUnmountable: nil, description: &description, type: &type)
        
        if !err {
            os_log("Error determining file system", log: enableFDELog, type: .error)
            return false
        }
        
        if type == "apfs" {
            os_log("Filesystem is APFS, enabling FileVault", log: enableFDELog)
            return true
        } else {
            os_log("Filesystem is not APFS, skipping FileVault", log: enableFDELog, type: .error)
            return false
        }
    }
    
    fileprivate func isFdeEnabled() -> Bool {
        // determine if FV is already running
        if cliTask("/usr/bin/fdesetup", arguments: ["status"]).contains("FileVault is Off") {
            return false
        } else {
            return true
        }
    }
}
