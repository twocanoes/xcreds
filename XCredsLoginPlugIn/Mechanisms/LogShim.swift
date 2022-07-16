//
//  LogShim.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/4/22.
//

import Foundation

let noLoMechlog = ""
enum ErrorType {
case error
case info
    case noLoMechlog
    case createUserLog
    case `default`
case debug
}
func os_log(_:String,log:String="",type:ErrorType = .info, _ extra1:String?="",_ extra2:String?="",_ extra3:String?="",_ extra4:String?="",_ extra5:String?="",_ extra6:String?="",_ extra7:String?="",_ extra8:String?="")  {

}
