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
        var rate = DefaultsOverride.standardOverride.double(forKey: PrefKeys.refreshRateHours.rawValue)
        var minutesRate = DefaultsOverride.standardOverride.double(forKey: PrefKeys.refreshRateMinutes.rawValue)

        if minutesRate < 0 {
            minutesRate=0
        }

        else if minutesRate > 60 {
            minutesRate=60
        }
        if rate < 0 {
            rate = 0
        }
        else if rate > 168 {
            rate = 168
        }
        nextCheckTime = Date(timeIntervalSinceNow: (rate*60+minutesRate)*60)
        NotificationCenter.default.post(name: NSNotification.Name("CheckTokenStatus"), object: self, userInfo:["NextCheckTime":nextCheckTime])

    }
    func startCredentialCheck()  {
        TCSLogWithMark()

        if let timer = timer, timer.isValid==true {
            return
        }

        nextCheckTime=Date()
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
        TCSLogWithMark("checking token")
        if nextCheckTime>Date() {
            TCSLogWithMark("Token will be checked at \(nextCheckTime)")

            NotificationCenter.default.post(name: NSNotification.Name("CheckTokenStatus"), object: self, userInfo:["NextCheckTime":nextCheckTime])
            return
        }
        setNextCheckTime()
        TCSLogWithMark("Checking token now (\(Date())). Next token check will be at \(nextCheckTime)")

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
                    sharedMainMenu.signedIn=true
                    sharedMainMenu.buildMenu()
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
