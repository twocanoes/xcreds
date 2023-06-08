//
//  ScheduleManager.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa

class ScheduleManager {

    static let shared=ScheduleManager()
    var nextCheckTime = Date()
    var timer:Timer?
    func setNextCheckTime() {
        if let timer = timer, timer.isValid==true {
            return
        }
        var rate = DefaultsOverride.standardOverride.integer(forKey: PrefKeys.refreshRateHours.rawValue)

        if rate < 1 {
            rate = 1
        }
        else if rate > 168 {
            rate = 168
        }
        nextCheckTime = Date(timeIntervalSinceNow: TimeInterval(rate*60*60))

    }
    func startCredentialCheck()  {

        setNextCheckTime()
        timer=Timer.scheduledTimer(withTimeInterval: 60*5, repeats: true, block: { timer in //check every 5 minutes
            self.checkToken()
        })
        self.checkToken()
    }
    func stopCredentialCheck()  {
        if let timer = timer, timer.isValid==true {
            timer.invalidate()

        }
    }
    func checkToken()  {
//        // we have not resolved the tokenEndpoint yet, so pop up a window
//        if DefaultsOverride.standardOverride.string(forKey: PrefKeys.tokenEndpoint.rawValue) == nil {
//            DispatchQueue.main.async {
//                SignInMenuItem().doAction()
//            }
//            return
//        }

        if nextCheckTime>Date() {
            TCSLogWithMark("Token will be checked at \(nextCheckTime)")
            return
        }
        setNextCheckTime()
        TokenManager.shared.getNewAccessToken(completion: { isSuccessful, hadConnectionError in

            if hadConnectionError==true {
                if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.showDebug.rawValue) == true {

                    NotifyManager.shared.sendMessage(message: "Could not check token.")
                }

                return
            }
            else if isSuccessful == true {

                if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.showDebug.rawValue) == true {
                    NotifyManager.shared.sendMessage(message: "Password unchanged")
                }
                DispatchQueue.main.async {
                    mainMenu.signedIn=true
                    mainMenu.buildMenu()
                }


            }
            else {
                //don't stop cred check otherwise it doesn't get restarted.
//                self.stopCredentialCheck()
                if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.showDebug.rawValue) == true {

                    NotifyManager.shared.sendMessage(message: "Password changed or not set")
                }
                DispatchQueue.main.async {

                    SignInMenuItem().doAction()
                }

            }
        })

    }

}
