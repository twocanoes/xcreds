//
//  Logger.swift
//  XCreds
//
//  Created by Timothy Perfitt on 7/5/22.
//

import Foundation
func TCSLogWithMark(_ message: String = "",
             file: String = #file, line: Int = #line, function: String = #function ) {

//    let date = Date()
    
    let comp = file.components(separatedBy: "/")
    if let lastPart = comp.last{
        TCSLog("\(lastPart):\(line) \(function) \(message)")

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
