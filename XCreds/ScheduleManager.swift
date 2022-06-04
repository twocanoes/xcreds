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

        timer=Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { timer in
            TokenManager.shared.getNewAccessToken(completion: { isSuccessful, hadConnectionError in

                if hadConnectionError==true {
                    NotifyManager.shared.sendMessage(message: "Could not check token.")

                    return
                }
                else if isSuccessful == true {
                    NotifyManager.shared.sendMessage(message: "Azure password unchanged")

                }
                else {
                    timer.invalidate()
                    NotifyManager.shared.sendMessage(message: "Azure password changed or not set")
                    DispatchQueue.main.async {
                        mainMenu.webView = WebViewController()
                        mainMenu.webView?.window!.forceToFrontAndFocus(nil)
                        mainMenu.webView?.run()

                    }

                }
            })
        })
    }
    func stopCredentialCheck()  {
        if let timer = timer, timer.isValid==true {
            timer.invalidate()

        }
    }
}
