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
        switch extensionState{
            
        case .none:
            break
        case .deviceRegistering:
            if let deviceRegisterCompletion = deviceRegisterCompletion {
                deviceRegisterCompletion(.failed)
            }
        case .essoProcessing:
            //maybe redirect to essoURL?
            self.authorizationRequest?.complete(error: NSError(domain: "tcs", code: -1, userInfo: [NSLocalizedDescriptionKey:"userAuth failure"]))
        }
       

    }
    
    func tokenResponse(tokens: OIDCLite.TokenResponse) {
        
        switch extensionState{
            
        case .none:
            break
        case .deviceRegistering:
            deviceRegister()
            
        case .essoProcessing:
            var headers:[String:String]? = nil
            if let accessToken = tokens.accessToken{
                headers=["Bearer":accessToken]
            }
            


            if let url = self.url, let response = HTTPURLResponse.init(url: url, statusCode: 302, httpVersion: nil, headerFields: headers) {
                self.authorizationRequest?.complete(httpResponse: response, httpBody: nil)
            }

        }
        
//        let headers: [String:String] = [
//            "Location": webViewURL.absoluteString,
//            "Set-Cookie": combineCookies(cookies: cookies)
//        ]
//        storeCookies(cookies)
        
        

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
        
        if let tScopes = loginManager?.extensionData[PrefKeys.scopes.rawValue] as? [String] {
            scopes = tScopes
        }


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
                let cookies = getCookies()
                
                if let cookies = cookies {
                    request.setValue(combineCookies(cookies: cookies), forHTTPHeaderField: "Cookie")
                }
                request.httpShouldHandleCookies=true
                
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
//                if let url = self.url, let response = HTTPURLResponse.init(url: url, statusCode: 302, httpVersion: nil, headerFields: headers) {
//                    self.authorizationRequest?.complete(httpResponse: response, httpBody: nil)
//                }
//            })
//        }
//
//    }
}
extension AuthenticationViewController:ExtensionAuthorizationRequestProtocol {

    func process(_ request:ASAuthorizationProviderExtensionAuthorizationRequest){
        essoURL=request.url
        request.presentAuthorizationViewController(completion: { (success, error) in
//            let urlRequest = URLRequest(url: self.url!)
//
//            self.webView.load(urlRequest)
            
            if error != nil {
                request.complete(error: error!)
                return
            }
            self.setupWebViewAndDelegate()

        })
    }
}
extension AuthenticationViewController: ASAuthorizationProviderExtensionAuthorizationRequestHandler {

    public func beginAuthorization(with authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest) {
        oidcLite?.delegate=self
        
        extensionState = .essoProcessing
        self.authorizationRequest = authorizationRequest
//        request.doNotHandle()
        process(authorizationRequest)
    }
}
