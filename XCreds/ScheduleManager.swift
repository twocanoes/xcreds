//
//  ScheduleManager.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa

class ScheduleManager {

    static let shared=ScheduleManager()

    var timer:Timer?
    func startCredentialCheck()  {
        if let timer = timer, timer.isValid==true {
            return
        }
        var rate = UserDefaults.standard.integer(forKey: PrefKeys.refreshRateHours.rawValue)

        if rate < 1 {
            rate = 1
        }
        else if rate > 168 {
            rate = 168
        }
        timer=Timer.scheduledTimer(withTimeInterval: TimeInterval(10), repeats: true, block: { timer in
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
//        if UserDefaults.standard.string(forKey: PrefKeys.tokenEndpoint.rawValue) == nil {
//            DispatchQueue.main.async {
//                SignInMenuItem().doAction()
//            }
//            return
//        }

        TokenManager.shared.getNewAccessToken(completion: { isSuccessful, hadConnectionError in

            if hadConnectionError==true {
                if UserDefaults.standard.bool(forKey: PrefKeys.showDebug.rawValue) == true {

                    NotifyManager.shared.sendMessage(message: "Could not check token.")
                }

                return
            }
            else if isSuccessful == true {

                if UserDefaults.standard.bool(forKey: PrefKeys.showDebug.rawValue) == true {
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
                if UserDefaults.standard.bool(forKey: PrefKeys.showDebug.rawValue) == true {

                    NotifyManager.shared.sendMessage(message: "Password changed or not set")
                }
                DispatchQueue.main.async {

                    SignInMenuItem().doAction()
                }

            }
        })

    }

}
