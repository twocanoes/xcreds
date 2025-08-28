//
//  LogOnly.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/23/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import Security.AuthorizationTags
import SecurityInterface.SFAuthorizationPluginView
import os.log
import LocalAuthentication

/// AuthorizationPlugin mechanism that simply logs the hint and context values that are being passed around.
@available(macOS, deprecated: 11)
class LogOnly : XCredsBaseMechanism {

    let contextKeys = [kAuthorizationEnvironmentUsername,
                       kAuthorizationEnvironmentPassword,
                       kAuthorizationEnvironmentShared,
                       kAuthorizationRightExecute,
                       kAuthorizationEnvironmentIcon,
                       kAuthorizationEnvironmentPrompt]
    

    // class to iterate anything in the context and hits and print them out
    // heavily influenced by the Apple NullAuth sample code
    
    @objc override  func run() {
        TCSLogErrorWithMark("LogOnly mech starting")

        TCSLogErrorWithMark("Printing security context arguments")
        getArguments()
        TCSLogErrorWithMark("Printing LAContext Tokens")
//        getTokens()

        TCSLogErrorWithMark("Printing all context values:")
        for item in contextKeys {
//            TCSLogErrorWithMark("\(item)")

            if let result = getContextString(type: item) {
                TCSLogErrorWithMark("Context item \(item):\(result)")
            }
        }

        TCSLogErrorWithMark("Printing all hint values:")
        let hintKeys = HintType.allCases.map{$0.rawValue}
        for item in hintKeys {
//            TCSLogErrorWithMark("\(item)")

            if let hintType = HintType(rawValue: item) {
                if let result = getHint(type: hintType) as? String {
                    TCSLogErrorWithMark("Hint item \(item):\(result)")
                }
            }
        }
        TCSLogErrorWithMark("LogOnly mech complete")
        let _ = allowLogin()
        TCSLogErrorWithMark("LogOnly mech complete")
    }
    func getArguments() {
        var value : UnsafePointer<AuthorizationValueVector>? = nil
        let error = mechCallbacks.GetArguments(mechEngine, &value)
        if error != noErr {
//            TCSLogErrorWithMark("getArguments: \(error)")
        }
    }

    // log only
    func getTokens() {
        TCSLogErrorWithMark()
        if #available(OSX 10.13, *) {
            TCSLogErrorWithMark("GetLAContext")

            var value : Unmanaged<CFArray>?
//            defer {value?.release()}

            //    public var GetTokenIdentities: @convention(c) (AuthorizationEngineRef, CFTypeRef, UnsafeMutablePointer<Unmanaged<CFArray>?>?) -> OSStatus


            //    public var GetLAContext: @convention(c) (AuthorizationEngineRef, UnsafeMutablePointer<Unmanaged<CFTypeRef>?>?) -> OSStatus

            var laContext:Unmanaged<AnyObject>?

            let status = mechCallbacks.GetLAContext(mechEngine,&laContext)
            if status != noErr{
            }
            else {
                TCSLogErrorWithMark("no error")

                let error = mechCallbacks.GetTokenIdentities(mechEngine, laContext as CFTypeRef, &value)

                TCSLogWithMark( "Got TokenIdentities2")

                if error != noErr {
                    TCSLogErrorWithMark("GetTokenIdentities error:")
                }
                else {
                    TCSLogWithMark( "Got TokenIdentities")
//                    TCSLogWithMark(value.debugDescription)
                }
            }
        } else {
            os_log("Tokens are not supported on this version of macOS", log: noLoMechlog, type: .default)

        }
    }

}

