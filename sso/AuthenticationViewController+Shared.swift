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

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.authorizationRequest?.doNotHandle()
    }
    
    func setupWebViewAndDelegate(withURL url:URL ) {
        if TCSBetaCheckController().isExpired()==true {
            TCSLogWithMark("Beta expired")
            return
        }
        Task{
            webView.navigationDelegate=self
            TCSLogWithMark("loading request");
            var request = URLRequest(url: url)
            request.httpShouldHandleCookies=true
            webView.load(request)
            
        }
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let webViewURL = webView.url else {
            return
        }
        TCSLogWithMark("redirect: \(webViewURL.absoluteString)")

        var codeValue:String?
        let components = URLComponents(url: webViewURL, resolvingAgainstBaseURL: false)
        if let code = components?.queryItems?.first(where: { item in
            
            item.name=="code"
        }){
            TCSLogWithMark("setting code value to \(code.value ?? "")")
            codeValue = code.value
        }
        switch extensionState{
            
        case .none:
            TCSLogWithMark("nothing to process")
            break
        case .deviceRegistering:
            TCSLogWithMark("deviceRegistering")
            if let _=codeValue, let callbackURLString = extensionData["redirectURI"] as? String, webViewURL.absoluteString.starts(with: callbackURLString) == true {
                guard let pssoKeys =  pssoKeys() else {
                    TCSLogWithMark("no psso keys")
                    return
                }
                Task{
                    TCSLogWithMark("gettihng loginManager")
                    if let loginManager = loginManager {
                        TCSLogWithMark("setPSSOLoginConfig")
                        await self.setPSSOLoginConfig(loginManager: loginManager)
                    }
                    
                    guard  var components = URLComponents(url: webViewURL, resolvingAgainstBaseURL: false) else {
                        TCSLogWithMark("no components")

                        return
                    }
                    
                    var cs = CharacterSet.urlQueryAllowed
                    cs.remove("+")
                    
                    let queryParams = ["deviceUUID":pssoKeys.deviceUUID, "deviceSigningKey": pssoKeys.deviceSigningKey,
                                       "deviceEncryptionKey": pssoKeys.deviceEncryptionKey,
                                       "signKeyID": pssoKeys.signKeyID,
                                       "encKeyID": pssoKeys.encKeyID]
                    
                    TCSLogWithMark("getting deviceRegistrationEndpoint")
                    
                    
                        
                    guard  let issuer=self.extensionData["IssuerHostname"] as? String, let deviceRegistrationEndpointPath = self.extensionData["deviceRegistrationEndpoint"] as? String, let registerPrefsComponent = URL(string: "https://\(issuer)/\(deviceRegistrationEndpointPath)") else {

                        TCSLogWithMark("error getting deviceRegistrationEndpoint. extension data:\(extensionData)")

                        deviceRegisterCompletion?(.failed)
                        return
                    }
                   
                    
                    components.host = registerPrefsComponent.host
                    components.path = registerPrefsComponent.path
                    components.scheme = registerPrefsComponent.scheme
                    
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
                    TCSLogWithMark("sending url request")

                    var request = URLRequest(url: componentsURL)
                    request.httpShouldHandleCookies=true
                    do {
                        
                        
                        let (_, _) = try await URLSession.shared.data(for: request)
                        deviceRegisterCompletion?(.success)
                        TCSLogWithMark("deviceRegisterCompletion success")
                        extensionState = .none

                    }
                    catch {
                        TCSLogWithMark("deviceRegisterCompletion failed: \(error.localizedDescription)")

                        deviceRegisterCompletion?(.failed)
                        
                    }
                    
                }
            }
            else {
                TCSLogWithMark("No code so not catching redirect")
            }
            
        case .essoProcessing:
            if let _=codeValue, let callbackURLString = extensionData["redirectURI"] as? String, webViewURL.absoluteString.starts(with: callbackURLString) == true {
                
                TCSLogWithMark("essoProcessing")
                
                var headers:[String:String] =  [:]
                
                TCSLogWithMark("url = \(url?.debugDescription ?? "")")
                TCSLogWithMark("codeValue = \(codeValue?.debugDescription ?? "")")
                
                if let url = url, let codeValue = codeValue {
                    TCSLogWithMark()
                    let redirectURLString = url.absoluteString + "?code=" + codeValue
                    let redirectURL = URL(string: redirectURLString)
                    headers["Location"]=redirectURLString
                    TCSLogWithMark(headers["Location"] ?? "")
                    
                    //                        if let accessToken = tokens.accessToken{
                    //                            headers["Bearer"]=accessToken
                    //                        }
                    TCSLogWithMark("Url : \(url.description )")
                    
                    
                    if let redirectURL=redirectURL, let response = HTTPURLResponse.init(url: redirectURL, statusCode: 302, httpVersion: nil, headerFields: headers) {
                        TCSLogWithMark()
                        
                        if let authorizationRequest = self.authorizationRequest {
                            TCSLogWithMark("Completing authorization request")
                            authorizationRequest.complete(httpResponse: response, httpBody: nil)
                        }
                        TCSLogWithMark()
                        
                    }
                    TCSLogWithMark()
                }
            }
            else {
                TCSLogWithMark("No code so not catching redirect")
            }

        }

    }
}
extension AuthenticationViewController:ExtensionAuthorizationRequestProtocol {

    func process(_ request:ASAuthorizationProviderExtensionAuthorizationRequest){
        TCSLogWithMark()
        
        extensionData = request.extensionData

        request.presentAuthorizationViewController(completion: { (success, error) in
            TCSLogWithMark()
            
            if error != nil {
                TCSLogWithMark()
                request.complete(error: error!)
                return
            }
            
            if let issuer=self.extensionData["IssuerHostname"] as? String, let deviceRegistrationEndpointPath = self.extensionData["deviceRegistrationEndpoint"] as? String, let url = URL(string: "https://\(issuer)/\(deviceRegistrationEndpointPath)"){
               
                
                TCSLogWithMark("Loading webview from url: \(url.absoluteString)")
                TCSLogWithMark(url.absoluteString)
                self.setupWebViewAndDelegate(withURL: url)
            }
            else {
                TCSLogWithMark()
            }
            TCSLogWithMark()

        })
    }
}
extension AuthenticationViewController: ASAuthorizationProviderExtensionAuthorizationRequestHandler {

    public func beginAuthorization(with authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest) {
        if TCSBetaCheckController().isExpired()==true {
            TCSLogWithMark("Beta expired")
            return
        }

        
        TCSLogWithMark()
        if authorizationRequest.url.absoluteString.contains("code="){
            TCSLogWithMark("code found, so not handling")
            extensionState = .none
            authorizationRequest.doNotHandle()
            return
        }
//        oidcLite?.delegate=self
        TCSLogWithMark()
        self.authorizationRequest=authorizationRequest
        self.url=authorizationRequest.url
        extensionState = .essoProcessing
//        request.doNotHandle()
        TCSLogWithMark()
        process(authorizationRequest)
    }
}
