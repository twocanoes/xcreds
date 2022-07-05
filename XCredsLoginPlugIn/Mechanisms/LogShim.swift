//
//  LogShim.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/4/22.
//

import Foundation
//os_log("Unable to get uid.", log: keychainAddLog, type: .error)

let noLoMechlog = ""
enum ErrorType {
case error
case info
    case noLoMechlog
    case debug
    case `default`
}
func os_log(_:String,log:String,type:ErrorType = .info)  {

}
