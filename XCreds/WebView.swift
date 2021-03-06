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

class WebViewController: NSWindowController {

    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("WebView")
    }

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var cancelButton: NSButton!

    var oidcLite: OIDCLite?
    var password:String?
    func run() {

        var scopes: [String]?
        var clientSecret: String?

        if let clientSecretRaw = UserDefaults.standard.string(forKey: PrefKeys.clientSecret.rawValue),
           clientSecretRaw != "" {
            clientSecret = clientSecretRaw
        }

        if let scopesRaw = UserDefaults.standard.string(forKey: PrefKeys.scopes.rawValue) {
            scopes = scopesRaw.components(separatedBy: " ")
        }

        oidcLite = OIDCLite(discoveryURL: UserDefaults.standard.string(forKey: PrefKeys.discoveryURL.rawValue) ?? "NONE", clientID: UserDefaults.standard.string(forKey: PrefKeys.clientID.rawValue) ?? "NONE", clientSecret: clientSecret, redirectURI: UserDefaults.standard.string(forKey: PrefKeys.redirectURI.rawValue), scopes: ["profile", "openid", "offline_access"])
        webView.navigationDelegate = self
        oidcLite?.delegate = self
        oidcLite?.getEndpoints()

        if let tokenEndpoint = oidcLite?.OIDCTokenEndpoint {
            UserDefaults.standard.set(tokenEndpoint, forKey: PrefKeys.tokenEndpoint.rawValue)
        }

        clearCookies()

        if let url = oidcLite?.createLoginURL() {
            self.webView.load(URLRequest(url: url))
        }
    }

    @IBAction func clickCancel(_ sender: Any) {
        self.window?.close()
    }

    private func clearCookies() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                 for: records,
                                 completionHandler: {
                print("Removing Cookie")
            })
        }

        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
}

extension WebViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        print("WebDel:: Deciding Policy for: \(navigationAction.request.url?.absoluteString ?? "None")")

        // if it's a POST let's see what we're posting...
        if navigationAction.request.httpMethod == "POST" {
            // Azure snarfing
            if navigationAction.request.url?.host == "login.microsoftonline.com" {
                var javaScript = "document.getElementById('i0118').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                    if let rawPass = response as? String {
                        self.password=rawPass
                    }
//                        let alert = NSAlert.init()
//                        alert.messageText = "Your password is: \(rawPass)"
//                        RunLoop.main.perform {
//                                alert.runModal()
//                        }
//                    }
                })
                javaScript = "document.getElementById('confirmNewPassword').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                    if let rawPass = response as? String {
                        self.password=rawPass
                    }
                })
            } else if navigationAction.request.url?.host == "accounts.google.com" {
                // Google snarfing
                let javaScript = "document.querySelector('input[type=password]').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
//                    if let rawPass = response as? String,
//                       rawPass != "" {
//                        let alert = NSAlert.init()
//                        alert.messageText = "Your password is: \(rawPass)"
//                        RunLoop.main.perform {
//                            alert.runModal()
//                        }
//                    }
                })
            } else if navigationAction.request.url?.path.contains("verify") ?? false {
                // maybe OneLogin?
                let javaScript = "document.getElementById('input8').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
//                    if let rawPass = response as? String {
//                        let alert = NSAlert.init()
//                        alert.messageText = "Your password is: \(rawPass)"
//                        RunLoop.main.perform {
//                            alert.runModal()
//                        }
//                    }
                })
            }
        } else if navigationAction.request.httpMethod == "GET" && navigationAction.request.url?.path.contains("token/redirect") ?? false {
            // for Okta
            let javaScript = "document.getElementById('input74').value"
            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
//                if let rawPass = response as? String {
//                    let alert = NSAlert.init()
//                    alert.messageText = "Your password is: \(rawPass)"
//                    RunLoop.main.perform {
//                        alert.runModal()
//                    }
//                }
            })
        }

        // this is cleaner, but only works with Azure

        /*
         if navigationAction.request.httpMethod == "POST" {
         if let bodyData = navigationAction.request.httpBody,
         let bodyString = String(data: bodyData, encoding: .utf8) {
         if let queryDict = queryToDict(query: bodyString) {
         var cleanedDict = [String:String]()

         for queryPair in queryDict {
         if let valueClean = queryPair.value.removingPercentEncoding,
         let noB64 = Data(base64Encoded: valueClean),
         let noB64String = String(data: noB64, encoding: .utf8) {
         cleanedDict[queryPair.key] = noB64String
         } else {
         cleanedDict[queryPair.key] = queryPair.value
         }
         }

         if let password = cleanedDict["passwd"] {
         print("Password is.... \(password)")
         let alert = NSAlert()
         alert.messageText = "Your password is: \(password.removingPercentEncoding ?? "Unkown")"
         alert.runModal()
         }
         }
         }
         }
         */

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("WebDel:: Did Receive Redirect for: \(webView.url?.absoluteString ?? "None")")

        if let redirectURI = oidcLite?.redirectURI {
            if (webView.url?.absoluteString.starts(with: (redirectURI))) ?? false {
                var code = ""
                let fullCommand = webView.url?.absoluteString ?? ""
                let pathParts = fullCommand.components(separatedBy: "&")
                for part in pathParts {
                    if part.contains("code=") {
                        code = part.replacingOccurrences(of: redirectURI + "?" , with: "").replacingOccurrences(of: "code=", with: "")
                        oidcLite?.getToken(code: code)
                        return
                    }
                }
            }
        }
    }

    private func queryToDict(query: String) -> [String:String]? {
        let components = query.components(separatedBy: "&")
        var dictionary = [String:String]()

        for pairs in components {
            let pair = pairs.components(separatedBy: "=")
            if pair.count == 2 {
                dictionary[pair[0]] = pair[1]
            }
        }

        if dictionary.count == 0 {
            return nil
        }

        return dictionary
    }

}

extension WebViewController: OIDCLiteDelegate {

    func authFailure(message: String) {
        print("Auth failure :(")
        NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:[:])

    }

    func tokenResponse(tokens: OIDCLiteTokenResponse) {

        RunLoop.main.perform {
            self.window?.close()
            if let password = self.password {
            NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:
                    [
                        "password":password,
                        PrefKeys.accessToken.rawValue:tokens.accessToken ?? "",
                        PrefKeys.idToken.rawValue:tokens.idToken ?? "",
                        PrefKeys.refreshToken.rawValue:tokens.refreshToken ?? ""

                    ]
            )

            }
        }
    }
}
