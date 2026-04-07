//
//  XCredsLoggingHelper.swift
//  XCreds
//
//  Created by Timothy Perfitt on 3/24/26.
//

func xcredsSetup()  {
    let bundle = Bundle.findBundleWithName(name: "XCreds")

    if let bundle = bundle {
        let infoPlist = bundle.infoDictionary
        if let infoPlist = infoPlist,
            let build = infoPlist["CFBundleVersion"] as? String,
            let version = infoPlist["CFBundleShortVersionString"] as? String {
            
            VersionCheck.shared.reportLicenseUsage(identifier: "com.twocanoes.xcreds", appVersion:version,buildNumber: build, event: .checkin) { isSuccess in
                print(isSuccess)
            }
            
            TCSUnifiedLogger.shared().logString("------------------------------------------------------------------",level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("XCreds Login \(version).\(build)",level: LOGLEVELDEBUG, forceWriteToFile: true)
            if DefaultsOverride.standardOverride.bool(forKey: "showDebug")==false {
                TCSUnifiedLogger.shared().logString("Log showing only basic info and errors.",level: LOGLEVELDEBUG, forceWriteToFile: true)
                TCSUnifiedLogger.shared().logString("Set debugLogging to true to show verbose logging with",level: LOGLEVELDEBUG, forceWriteToFile: true)
                TCSUnifiedLogger.shared().logString("sudo defaults write /Library/Preferences/com.twocanoes.xcreds showDebug -bool true",level: LOGLEVELDEBUG, forceWriteToFile: true)
            }
            else {
                TCSUnifiedLogger.shared().logString("To disable verbose logging:",level: LOGLEVELDEBUG, forceWriteToFile: true)
                TCSUnifiedLogger.shared().logString("sudo defaults delete /Library/Preferences/com.twocanoes.xcreds showDebug",level: LOGLEVELDEBUG, forceWriteToFile: true)

            }
            TCSUnifiedLogger.shared().logString("NOTE: LOGGING HAS MOVED TO MACOS SYSTEM LOGGING ONLY", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("view logs with:", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("log stream --predicate '(message contains \"XCREDS\" or message contains \"OIDCLITE\")'", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("view previous 30 minutes of events with:", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("log show -last 30m --predicate '(message contains \"XCREDS\" or message contains \"OIDCLITE\")'", level: LOGLEVELDEBUG, forceWriteToFile: true)

            TCSUnifiedLogger.shared().logString("To see all logging options, go to https://twocanoes.com/knowledge-base/capturing-xcreds-logs/", level: LOGLEVELDEBUG, forceWriteToFile: true)

            TCSUnifiedLogger.shared().logString("------------------------------------------------------------------", level: LOGLEVELDEBUG, forceWriteToFile: true)


        }
    }

}
