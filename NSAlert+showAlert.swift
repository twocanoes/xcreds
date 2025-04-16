//
//  NSAlert+showAlert.swift
//  XCreds
//
//  Created by Timothy Perfitt on 4/15/25.
//

import Cocoa

extension NSAlert {

    static func showAlert(title: String?, message: String?, style: NSAlert.Style = .informational) {
        let alert = NSAlert()
        if let title = title {
            alert.messageText = title
        }
        if let message = message {
            alert.informativeText = message
        }
        alert.alertStyle = style
        alert.runModal()
    }

}
