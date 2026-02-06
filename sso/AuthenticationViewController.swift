//
//  AuthenticationViewController.swift
//  ssoe
//
//  Created by Timothy Perfitt on 3/25/24.
//

import Cocoa
import AuthenticationServices
import WebKit
import CryptoKit
import OIDCLite
class AuthenticationViewController: NSViewController {

    enum ExtensionState {
        case none
        case deviceRegistering
        case essoProcessing
    }
    var deviceRegisterCompletion:((ASAuthorizationProviderExtensionRegistrationResult) -> Void)?
//    var oidcLite:OIDCLite? = nil
    var url:URL?
    var essoURL:URL?
    var loginManager:ASAuthorizationProviderExtensionLoginManager?
    var authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest?
    var urlPath = ""
    var tokenEndpoint = "token"
    var issuer = ""
    var jwksEndpoint = ".well-known/jwks.json"
    var nonceEndpont = "nonce"
    var clientID = "psso"
    var registrationEndpoint = "register"

    var discoveryURLString = ""
    var scopes:[String]? = nil
    
    var additionalParameters:[String:String] = [:]
    var clientSecret = ""
    var extensionData: [AnyHashable : Any] = [:]
    var extensionState:ExtensionState = .none
    @IBOutlet weak var webView: WKWebView!
//    override func viewDidLoad() {
//        if let path = Bundle.main.path(forResource: "defaults", ofType: "plist"){
//            let defaultsInfoPlist = NSDictionary(contentsOfFile: path)
//            UserDefaults.standard.register(defaults: defaultsInfoPlist as! [String : Any])
//        }
//
//    }
    override func viewDidAppear() {
        super.viewDidAppear()
//        if let path = Bundle.main.path(forResource: "defaults", ofType: "plist"){
//            let defaultsInfoPlist = NSDictionary(contentsOfFile: path)
//            UserDefaults.standard.register(defaults: defaultsInfoPlist as! [String : Any])
//        }
        


        view.window?.setContentSize(NSMakeSize(600, 600))

    }
    override var nibName: NSNib.Name? {
        return NSNib.Name("AuthenticationViewController")
    }
}
