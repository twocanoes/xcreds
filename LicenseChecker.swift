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
            TCSLogErrorWithMark("setting trial date")
            UserDefaults.standard.setValue(Date(), forKey: "tts")
        }
        let firstLaunchDate = UserDefaults.standard.value(forKey: "tts") as? Date

        var trialState = LicenseState.trialExpired
        if let firstLaunchDate = firstLaunchDate {
            let secondsPassed = Date().timeIntervalSince(firstLaunchDate)
            let trialDaysLeft=trialDays-(Int(secondsPassed)/(24*60*60));
            TCSLogWithMark("trial days: \(secondsPassed)")

            if secondsPassed<Double(24*60*60*trialDays) {
                trialState = .trial(trialDaysLeft)
            }

        }
        else {
            TCSLogErrorWithMark("did not get first launch date")
        }
        let check = TCSLicenseCheck()
        let status = check.checkLicenseStatus("com.twocanoes.xcreds", withExtension: "")

        switch status {

        case .valid:
            TCSLogWithMark("valid license")
            return .valid
        case .expired:
            TCSLogErrorWithMark("expired license")
            return trialState

        case .invalid:
            TCSLogErrorWithMark("license invalid")
            return trialState
        case .unset:
            TCSLogErrorWithMark("No License")
            return trialState
        default:
            TCSLogErrorWithMark("invalid license")
            return trialState
        }

    }

}
