//
//  ChangePasswordMenuItem.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa

class ChangePasswordMenuItem: NSMenuItem {

    override var title: String {
        get {

            return "Change Password..."
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
        if let passwordChangeURLString = UserDefaults.standard.value(forKey: PrefKeys.passwordChangeURL.rawValue) as? String, passwordChangeURLString.count>0, let url = URL(string: passwordChangeURLString) {


            NSWorkspace.shared.open(url)
        }
    }
}
