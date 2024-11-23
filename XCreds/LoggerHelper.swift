//
//  Logger.swift
//  XCreds
//
//  Created by Timothy Perfitt on 7/5/22.
//


import Foundation
public func TCSLogWithMark(_ message: String = "",
             file: String = #file, line: Int = #line, function: String = #function ) {


    let comp = file.components(separatedBy: "/")
    if let lastPart = comp.last{
        if message.isEmpty{
            TCSLog("\(lastPart):\(line) \(function) \(message)")

        }
        else {
            TCSLog("      \(lastPart):\(line) \(function) \(message)")
        }

    }

}
func TCSLogInfoWithMark(_ message: String = "",
             file: String = #file, line: Int = #line, function: String = #function ) {


    let comp = file.components(separatedBy: "/")
    if let lastPart = comp.last{
        if message.isEmpty{
            TCSLogInfo("\(lastPart):\(line) \(function) \(message)")

        }
        else {
            TCSLogInfo("      \(lastPart):\(line) \(function) \(message)")
        }

    }

}
func TCSLogErrorWithMark(_ message: String = "",
             file: String = #file, line: Int = #line, function: String = #function ) {


    let comp = file.components(separatedBy: "/")
    if let lastPart = comp.last{
        if message.isEmpty{
            TCSLogError("\(lastPart):\(line) \(function) \(message)")

        }
        else {
            TCSLogError("      \(lastPart):\(line) \(function) \(message)")
        }

    }

}

//
//func Mark(
//             file: String = #file, line: Int = #line, function: String = #function ) {
//
//    let date = Date()
//
//    let comp = file.components(separatedBy: "/")
//    if let lastPart = comp.last{
//        TCSLog("\(date) FILE:\(lastPart) LINE:\(line) FUNCTION:\(function)")
//
//    }
//
//}
