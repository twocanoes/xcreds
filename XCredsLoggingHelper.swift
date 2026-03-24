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
            
            TCSLogInfoWithMark("------------------------------------------------------------------")
            TCSLogInfoWithMark("XCreds Login \(version).\(build)")
            if DefaultsOverride.standardOverride.bool(forKey: "showDebug")==false {
                TCSLogInfoWithMark("Log showing only basic info and errors.")
                TCSLogInfoWithMark("Set debugLogging to true to show verbose logging with")
                TCSLogInfoWithMark("sudo defaults write /Library/Preferences/com.twocanoes.xcreds showDebug -bool true")
            }
            else {
                TCSLogInfoWithMark("To disable verbose logging:")
                TCSLogInfoWithMark("sudo defaults delete /Library/Preferences/com.twocanoes.xcreds showDebug")

            }
            TCSUnifiedLogger.shared().logString("NOTE: LOGGING HAS MOVED TO MACOS SYSTEM LOGGING ONLY", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("view logs with:", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("log stream --predicate '(message contains \"XCREDS\" or message contains \"OIDCLITE\")'", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("view previous 30 minutes of events with:", level: LOGLEVELDEBUG, forceWriteToFile: true)
            TCSUnifiedLogger.shared().logString("log show -last 30m --predicate '(message contains \"XCREDS\" or message contains \"OIDCLITE\")'", level: LOGLEVELDEBUG, forceWriteToFile: true)


            TCSLogInfoWithMark("To see all logging options, go to https://twocanoes.com/knowledge-base/capturing-xcreds-logs/")
            TCSLogInfoWithMark("------------------------------------------------------------------")

        }
    }

}
