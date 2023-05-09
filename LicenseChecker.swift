//
//  LicenseChecker.swift
//  XCreds
//
//  Created by Timothy Perfitt on 3/28/23.
//

import Cocoa

class LicenseChecker: NSObject {
    enum LicenseState {
        case valid
        case invalid
        case trial(Int)
        case trialExpired
        case expired
    }

    func currentLicenseState() -> LicenseState {
        let trialDays = 14

        if UserDefaults.standard.value(forKey: "tts") == nil {
            UserDefaults.standard.setValue(Date(), forKey: "tts")
        }
        let firstLaunchDate = UserDefaults.standard.value(forKey: "tts") as? Date

        var trialState = LicenseState.trialExpired
        if let firstLaunchDate = firstLaunchDate {
            let secondsPassed = Date().timeIntervalSince(firstLaunchDate)
            let trialDaysLeft=trialDays-(Int(secondsPassed)/(24*60*60));

            if secondsPassed<Double(24*60*60*trialDays) {
                trialState = .trial(trialDaysLeft)
            }

        }
        let check = TCSLicenseCheck()
        let status = check.checkLicenseStatus("com.twocanoes.xcreds", withExtension: "")

        switch status {

        case .valid:
            TCSLogWithMark("valid license")
            return .valid
        case .expired:
            TCSLogWithMark("expired license")
            return trialState

        case .invalid:
            TCSLogWithMark("license invalid")
            return trialState
        case .unset:
            TCSLogWithMark("No License")
            return trialState
        default:
            TCSLogWithMark("invalid license")
            return trialState
        }

    }

}
