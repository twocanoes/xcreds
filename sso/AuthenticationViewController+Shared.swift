//
//  AuthenticationViewController+Shared.swift
//  Scissors
//
//  Created by Timothy Perfitt on 4/4/24.
//

import Foundation
import AuthenticationServices
import WebKit
import OIDCLite



protocol ExtensionAuthorizationRequestProtocol {
    func process(_ request:ASAuthorizationProviderExtensionAuthorizationRequest)
}

extension AuthenticationViewController:WKNavigationDelegate, OIDCLiteDelegate {
    func tokenFailure(message: String) {
        if let deviceRegisterCompletion = deviceRegisterCompletion {
            deviceRegisterCompletion(.failed)
        }

    }
    
    func tokenResponse(tokens: OIDCLite.TokenResponse) {
            deviceRegister()
        
    }
    

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.authorizationRequest?.doNotHandle()
    }

    func setupWebViewAndDelegate() {
        
        if let tDiscoveryURL = loginManager?.extensionData[PrefKeys.discoveryURL.rawValue] as? String {
            discoveryURLString = tDiscoveryURL
        }
        
        if let tRedirectURI = loginManager?.extensionData[PrefKeys.redirectURI.rawValue] as? String {
            redirectURI = tRedirectURI
        }
        if let tClientSecret = loginManager?.extensionData[PrefKeys.clientSecret.rawValue] as? String {
            clientSecret = tClientSecret
        }
        
        if let tClientID = loginManager?.extensionData[PrefKeys.clientID.rawValue] as? String {
            clientID = tClientID
        }
        
        if let tAdditionalParameters = loginManager?.extensionData[PrefKeys.AdditionalParameters.rawValue] as? [String:String] {
            additionalParameters = tAdditionalParameters
        }

//
//        let discoveryURL = UserDefaults.standard.string(forKey: PrefKeys.discoveryURL.rawValue) ?? ""
//
//        let clientID = UserDefaults.standard.string(forKey: PrefKeys.clientID.rawValue) ?? ""
//
//        let redirectURI = UserDefaults.standard.string(forKey: PrefKeys.redirectURI.rawValue) ?? ""
//        
//        let scopes = UserDefaults.standard.array(forKey: PrefKeys.scopes.rawValue) as? [String]
//
//        let clientSecret = UserDefaults.standard.string(forKey: PrefKeys.clientSecret.rawValue) ?? ""

        
//       let additionalParameters = ["access_type":"offline"]

        oidcLite = OIDCLite(discoveryURL: discoveryURLString, clientID:clientID, clientSecret: clientSecret, redirectURI: redirectURI, scopes: scopes, additionalParameters: additionalParameters)
        guard let oidcLite = oidcLite else {
            return
        }
        Task{
            oidcLite.delegate = self
            try? await oidcLite.getEndpoints()
            let url = oidcLite.createLoginURL()
            //        let url = URL(string: urlString)
            if let url = url {
                webView.navigationDelegate=oidcLite
                var request = URLRequest(url: url)
//                let cookies = getCookies()
                
//                if let cookies = cookies {
//                    request.setValue(combineCookies(cookies: cookies), forHTTPHeaderField: "Cookie")
//                }
//                request.httpShouldHandleCookies=true
                webView.load(request)
            }
        }
    }

//    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
//        guard let webViewURL = webView.url,
//        let callbackURLString = UserDefaults.standard.string(forKey: DefaultKeys.CallbackURLString.rawValue) else {
//            return
//        }
//
//        if (webViewURL.absoluteString.starts(with: callbackURLString) == true) {
//            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ cookies in
//                let headers: [String:String] = [
//                    "Location": webViewURL.absoluteString,
//                    "Set-Cookie": combineCookies(cookies: cookies)
//                ]
//                storeCookies(cookies)
//                if let response = HTTPURLResponse.init(url: url, statusCode: 302, httpVersion: nil, headerFields: headers) {
//                    self.authorizationRequest?.complete(httpResponse: response, httpBody: nil)
//                }
//            })
//        }
//
//    }
}
//extension AuthenticationViewController:ExtensionAuthorizationRequestProtocol {
//
//    func process(_ request:ASAuthorizationProviderExtensionAuthorizationRequest){
//        url=request.url
//        request.presentAuthorizationViewController(completion: { (success, error) in
//            if error != nil {
//                request.complete(error: error!)
//            }
//        })
//    }
//}
extension AuthenticationViewController: ASAuthorizationProviderExtensionAuthorizationRequestHandler {

    public func beginAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest) {
        self.authorizationRequest = request
        request.doNotHandle()
//        process(request)
    }
}
