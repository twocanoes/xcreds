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

extension AuthenticationViewController:WKNavigationDelegate {
//    func tokenFailure(message: String) {
//        switch extensionState{
//            
//        case .none:
//            break
//        case .deviceRegistering:
//            if let deviceRegisterCompletion = deviceRegisterCompletion {
//                deviceRegisterCompletion(.failed)
//            }
//        case .essoProcessing:
//            //maybe redirect to essoURL?
//            self.authorizationRequest?.complete(error: NSError(domain: "tcs", code: -1, userInfo: [NSLocalizedDescriptionKey:"userAuth failure"]))
//        }
//       
//
//    }
//    
//    func tokenResponse(tokens: OIDCLite.TokenResponse) {
//        
//        switch extensionState{
//            
//        case .none:
//            break
//        case .deviceRegistering:
//            deviceRegister()
//            
//        case .essoProcessing:
//            var headers:[String:String] =  [:]
//            
//            if let url = url, let accessToken = tokens.accessToken {
//                headers["Location"]=url.absoluteString+"?code="+accessToken
//            }
////            if let accessToken = tokens.accessToken{
////                headers["Bearer"]=accessToken
////            }
//            
//            if let url = self.url, let response = HTTPURLResponse.init(url: url, statusCode: 302, httpVersion: nil, headerFields: headers) {
//                self.authorizationRequest?.complete(httpResponse: response, httpBody: nil)
//            }
//
//        }
//        
////        let headers: [String:String] = [
////            "Location": webViewURL.absoluteString,
////            "Set-Cookie": combineCookies(cookies: cookies)
////        ]
////        storeCookies(cookies)
//        
//        
//
//    }
//    

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.authorizationRequest?.doNotHandle()
    }

    func setupWebViewAndDelegate(withURL url:URL ) {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                 for: records,
                                 completionHandler: {
                print("Removing Cookie")
            })
        }

//        if let cookies = HTTPCookieStorage.shared.cookies {
//            for cookie in cookies {
//                HTTPCookieStorage.shared.deleteCookie(cookie)
//            }
//        }

//        if let tDiscoveryURL = extensionData[PrefKeys.discoveryURL.rawValue] as? String {
//            discoveryURLString = tDiscoveryURL
//        }
//        
//        if let tRedirectURI = extensionData[PrefKeys.redirectURI.rawValue] as? String {
//            redirectURI = tRedirectURI
//        }
//        if let tClientSecret = extensionData[PrefKeys.clientSecret.rawValue] as? String {
//            clientSecret = tClientSecret
//        }
//        
//        if let tClientID = extensionData[PrefKeys.clientID.rawValue] as? String {
//            clientID = tClientID
//        }
//        
//        if let tAdditionalParameters = extensionData[PrefKeys.AdditionalParameters.rawValue] as? [String:String] {
//            additionalParameters = tAdditionalParameters
//        }
//        
//        if let tScopes = extensionData[PrefKeys.scopes.rawValue] as? [String] {
//            scopes = tScopes
//        }


////       let additionalParameters = ["access_type":"offline"]
//
//        oidcLite = OIDCLite(discoveryURL: discoveryURLString, clientID:clientID, clientSecret: clientSecret, redirectURI: redirectURI, scopes: scopes, additionalParameters: additionalParameters)
//        guard let oidcLite = oidcLite else {
//            return
//        }
        Task{
//            oidcLite.delegate = self
//            try? await oidcLite.getEndpoints()
//            let url = oidcLite.createLoginURL()
            //        let url = URL(string: urlString)
                webView.navigationDelegate=self
                var request = URLRequest(url: url)
//                let cookies = getCookies()
//                
//                if let cookies = cookies {
//                    request.setValue(combineCookies(cookies: cookies), forHTTPHeaderField: "Cookie")
//                }
                request.httpShouldHandleCookies=true
        
            
                webView.load(request)
            
        }
    }

    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let webViewURL = webView.url else {
            return
        }
        var codeValue:String?
        let components = URLComponents(url: webViewURL, resolvingAgainstBaseURL: false)
        if let code = components?.queryItems?.first(where: { item in
            item.name=="code"
        }){
            codeValue = code.value
        }
        
        
        
//
//        switch extensionState{
//            
//        case .none:
//            break
//        case .deviceRegistering:
//        case .deviceRegistering:
//            deviceRegister()
//            
//        case .essoProcessing:
//            var headers:[String:String] =  [:]
//            
//            if let url = url {
//                headers["Location"]=url.absoluteString+"?code="+accessToken
//            }
            //            if let accessToken = tokens.accessToken{
            //                headers["Bearer"]=accessToken
            //            }
            
//            if let url = self.url, let response = HTTPURLResponse.init(url: url, statusCode: 302, httpVersion: nil, headerFields: headers) {
//                self.authorizationRequest?.complete(httpResponse: response, httpBody: nil)
//            }
//            
        
        
        if let _=codeValue, let callbackURLString = extensionData["redirectURI"] as? String, webViewURL.absoluteString.starts(with: callbackURLString) == true {
            //            deviceRegister(code: codeValue)
            guard let pssoKeys =  pssoKeys() else {
                return
            }
            Task{
                if let loginManager = loginManager {
                    await self.setPSSOLoginConfig(loginManager: loginManager)
                }
                
                
                
                /*
                 var deviceUUID:String
                 var deviceSigningKey:String
                 var deviceEncryptionKey:String
                 var signKeyID:String
                 var encKeyID:String
                 
                 */
                
                
                guard  var components = URLComponents(url: webViewURL, resolvingAgainstBaseURL: false) else {
                    return
                }
                

                var cs = CharacterSet.urlQueryAllowed
                cs.remove("+")

                let queryParams = ["deviceUUID":pssoKeys.deviceUUID, "deviceSigningKey": pssoKeys.deviceSigningKey,
                                   "deviceEncryptionKey": pssoKeys.deviceEncryptionKey,
                                   "signKeyID": pssoKeys.signKeyID,
                                   "encKeyID": pssoKeys.encKeyID]
                                   

                components.host = "psso.twocanoes.com"
                components.path = "/register"
                components.scheme = "https"
                
//                components.queryItems?.append(URLQueryItem(name: "deviceUUID", value: pssoKeys.deviceUUID))
//                components.queryItems?.append(URLQueryItem(name: "deviceSigningKey", value: pssoKeys.deviceSigningKey))
//                components.queryItems?.append(URLQueryItem(name: "deviceEncryptionKey", value: pssoKeys.deviceEncryptionKey))
//                components.queryItems?.append(URLQueryItem(name: "signKeyID", value: pssoKeys.signKeyID))
//                components.queryItems?.append(URLQueryItem(name: "encKeyID", value: pssoKeys.encKeyID))
                let percentEncoded = queryParams.map {
                    $0.addingPercentEncoding(withAllowedCharacters: cs)!
                    + "=" + $1.addingPercentEncoding(withAllowedCharacters: cs)!
                }.joined(separator: "&")
                
                if let percentEncodedQuery = components.percentEncodedQuery {
                    components.percentEncodedQuery =  percentEncodedQuery + "&" + percentEncoded
                }

                
                guard let componentsURL = components.url else {
                    return
                }
                
                var request = URLRequest(url: componentsURL)
                request.httpShouldHandleCookies=true
                do {
                    
                    
                    let (data, _) = try await URLSession.shared.data(for: request)
                    TCSLogWithMark(data.base64EncodedString())
                    deviceRegisterCompletion?(.success)

                }
                catch {
                    deviceRegisterCompletion?(.failed)

                }
//                webView.load(request)
                
                //            webView.load(request)
                //                self.authorizationRequest?.complete()
            }
        }

    }
}
extension AuthenticationViewController:ExtensionAuthorizationRequestProtocol {

    func process(_ request:ASAuthorizationProviderExtensionAuthorizationRequest){
        essoURL=request.url
        extensionData = request.extensionData

        request.presentAuthorizationViewController(completion: { (success, error) in
//            let urlRequest = URLRequest(url: self.url!)
//
//            self.webView.load(urlRequest)
            
            if error != nil {
                request.complete(error: error!)
                return
            }
            
            if let urlString = self.extensionData["deviceRegistrationEndpoint"] as? String, let url = URL(string: urlString){
                self.setupWebViewAndDelegate(withURL: url)
            }

        })
    }
}
extension AuthenticationViewController: ASAuthorizationProviderExtensionAuthorizationRequestHandler {

    public func beginAuthorization(with authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest) {
        if authorizationRequest.url.absoluteString.contains("code="){
            extensionState = .none
            authorizationRequest.doNotHandle()
            return
        }
//        oidcLite?.delegate=self
        self.authorizationRequest=authorizationRequest
        self.url=authorizationRequest.url
        extensionState = .essoProcessing
//        request.doNotHandle()
        process(authorizationRequest)
    }
}
