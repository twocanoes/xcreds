//
//  CheckTokenMenuItem.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class CheckTokenMenuItem: NSMenuItem {

    override var isHidden: Bool {
        get {
            if let _ = UserDefaults.standard.object(forKey: PrefKeys.accessToken.rawValue) as? String {
                return false
            } else {
                return true
            }
        }
        set {
            return
        }
    }

    override var title: String {
        get {
            "Check Token"
        }
        set {
            return
        }
    }

    init() {
         super.init(title: "", action: #selector(doAction), keyEquivalent: "")
         self.target = self
     }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func doAction() {
//        let alert = NSAlert()
//
//        if TokenManager.shared.getNewAccessToken() {
//            alert.messageText = "Success!"
//        } else {
//            alert.messageText = "Failure!"
//        }
//
//        alert.runModal()
    }
}
