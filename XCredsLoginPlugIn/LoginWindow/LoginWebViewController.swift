//
//  WebView.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation
import Cocoa
import WebKit
import OIDCLite
import OpenDirectory

class LoginWebViewController: WebViewController, DSQueryable {

    let uiLog = "uiLog"
//    var internalDelegate:XCredsMechanismProtocol?
    var mechanismDelegate:XCredsMechanismProtocol?
//    }
    var loginProgressWindowController:LoginProgressWindowController?
    @IBOutlet weak var backgroundImageView: NSImageView!

    override func viewDidAppear() {
        TCSLogWithMark("loading page")
        loadPage()

    }


    override func showErrorMessageAndDeny(_ message:String){

            mechanismDelegate?.denyLogin(message:message)
            return
        }


    override func credentialsUpdated(_ credentials:Creds){
        
        if let res = mechanismDelegate?.setupHints(fromCredentials: credentials, password: password ?? "" ){

            switch res {

            case .success:
                break
            case .failure(let message):
                TCSLogWithMark("error setting up hints, reloading page:\(message)")
                loadPage()

            }
        }

    }

}



extension String {

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-._")
        return self.filter {okayChars.contains($0) }
    }
}
