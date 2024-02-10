//
//  NSTaskWrapper.swift
//  NoAD
//
//  Created by Joel Rennich on 3/29/16.
//  Copyright © 2016 Trusource Labs. All rights reserved.
//

// v. 1.4.1

import Foundation
import SystemConfiguration
import IOKit

/////// A simple wrapper around NSTask
///////
/////// - Parameters:
///////   - command: The `String` of the command to run. A full path to the binary is not required. Arguments can be in the main string.
///////   - arguments: An optional `Array` of `String` values that represent the arguments given to the command. Defaults to 'nil'.
///////   - waitForTermination: An optional `Bool` Should the the output be delayed until the task exits. Deafults to 'true'.
/////// - Returns: The combined result of standard output and standard error from the command.
////public func cliTask(_ command: String, arguments: [String]? = nil, waitForTermination: Bool = true) -> String {
////
////    var commandLaunchPath: String
////    var commandPieces: [String]
////
////    if arguments == nil {
////        // turn the command into an array and get the first element as the launch path
////        commandPieces = command.components(separatedBy: " ")
////        // loop through the components and see if any end in \
////        if command.contains("\\") {
////
////            // we need to rebuild the string with the right components
////            var x = 0
////            for line in commandPieces {
////                if line.last == "\\" {
////                    commandPieces[x] = commandPieces[x].replacingOccurrences(of: "\\", with: " ") + commandPieces.remove(at: x+1)
////                    x -= 1
////                }
////                x += 1
////            }
////        }
////        commandLaunchPath = commandPieces.remove(at: 0)
////    } else {
////        commandLaunchPath = command
////        commandPieces = arguments!
////        //TCSLogWithMark(commandLaunchPath + " " + arguments!.joinWithSeparator(" "))
////    }
////
////    // make sure the launch path is the full path -- think we're going down a rabbit hole here
////
////    if !commandLaunchPath.contains("/") {
////        let realPath = which(commandLaunchPath)
////        commandLaunchPath = realPath
////    }
////
////    // set up the NSTask instance and an NSPipe for the result
////
////    let myTask = Process()
////    let myPipe = Pipe()
////    let myInputPipe = Pipe()
////    let myErrorPipe = Pipe()
////
////    // Setup and Launch!
////
////    if FileManager.default.isExecutableFile(atPath: commandLaunchPath) == false {
////        return ""
////    }
////    myTask.launchPath = commandLaunchPath
////    myTask.arguments = commandPieces
////    myTask.standardOutput = myPipe
////    myTask.standardInput = myInputPipe
////    myTask.standardError = myErrorPipe
////
////    myTask.launch()
////    if waitForTermination == true {
////        myTask.waitUntilExit()
////    }
////
////    let data = myPipe.fileHandleForReading.readDataToEndOfFile()
////    let error = myErrorPipe.fileHandleForReading.readDataToEndOfFile()
////    let outputError = NSString(data: error, encoding: String.Encoding.utf8.rawValue)! as String
////    let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
////
////    return output + outputError
////}
////
////public func cliTaskNoTerm( _ command: String) -> String {
////
////    // This is here because klist -v won't actually trigger the NSTask termination
////
////    // turn the command into an array and get the first element as the launch path
////
////    var commandPieces = command.components(separatedBy: " ")
////
////    // loop through the components and see if any end in \
////
////    if command.contains("\\") {
////
////        // we need to rebuild the string with the right components
////        var x = 0
////
////        for line in commandPieces {
////            if line.last == "\\" {
////                commandPieces[x] = commandPieces[x].replacingOccurrences(of: "\\", with: " ") + commandPieces.remove(at: x+1)
////                x -= 1
////            }
////            x += 1
////        }
////    }
////
////    var commandLaunchPath = commandPieces.remove(at: 0)
////
////    // make sure the launch path is the full path -- think we're going down a rabbit hole here
////
////    if !commandLaunchPath.contains("/") {
////        let realPath = which(commandLaunchPath)
////        commandLaunchPath = realPath
////    }
////
////    // set up the NSTask instance and an NSPipe for the result
////
////    let myTask = Process()
////    let myPipe = Pipe()
////    let myInputPipe = Pipe()
////    let myErrorPipe = Pipe()
////
////    // Setup and Launch!
////
////    myTask.launchPath = commandLaunchPath
////    myTask.arguments = commandPieces
////    myTask.standardOutput = myPipe
////    myTask.standardInput = myInputPipe
////    myTask.standardError = myErrorPipe
////
////    myTask.launch()
////
////    let data = myPipe.fileHandleForReading.readDataToEndOfFile()
////    let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
////
////    return output
////}
//
//
//// this is a quick routine to get the console user
//
//public func getConsoleUser() -> String {
//    var uid: uid_t = 0
//    var gid: gid_t = 0
//    var userName: String = ""
//
//    // use SCDynamicStore to find out who the console user is
//
//    let theResult = SCDynamicStoreCopyConsoleUser( nil, &uid, &gid)
//    userName = theResult! as String
//    return userName
//}
//
////public func getSerial() -> String {
////
////    guard let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice")),
////        let platformSerialNumberKey: CFString = kIOPlatformSerialNumberKey as CFString? else
////    {
////        return "Unknown"
////    }
////
////    let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, platformSerialNumberKey, kCFAllocatorDefault, 0)
////    let serialNumber = serialNumberAsCFString?.takeUnretainedValue() as! String
////    return serialNumber
////
////}
//
//// get hardware MAC addresss
//
//public func getMAC() -> String {
//
//    let myMACOutput = cliTask("/sbin/ifconfig -a").components(separatedBy: "\n")
//    var myMac = ""
//
//    for line in myMACOutput {
//        if line.contains("ether") {
//            myMac = line.replacingOccurrences(of: "ether", with: "").trimmingCharacters(in: CharacterSet.whitespaces)
//            break
//        }
//    }
//    return myMac
//}
//
//
//// private function to get the path to the binary if the full path isn't given
//
//private func which(_ command: String) -> String {
//    let task = Process()
//    task.launchPath = "/usr/bin/which"
//    task.arguments = [command]
//
//    let whichPipe = Pipe()
//    task.standardOutput = whichPipe
//    task.launch()
//
//    let data = whichPipe.fileHandleForReading.readDataToEndOfFile()
//    let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
//    
//    if output == "" {
//        NSLog("Binary doesn't exist")
//    }
//    
//    return output.components(separatedBy: "\n").first!
//    
//}
//public func getSerial() -> String {
//    let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
//    let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
//    return serialNumberAsCFString?.takeUnretainedValue() as! String
//}

