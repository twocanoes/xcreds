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

    var password:String?
    func loadPage() {

        webView.navigationDelegate = self
        TokenManager.shared.oidc().delegate = self
        clearCookies()
        if let url = TokenManager.shared.oidc().createLoginURL() {
            TCSLogWithMark()
            self.webView.load(URLRequest(url: url))
        }
        else {
            let allBundles = Bundle.allBundles
            for currentBundle in allBundles {
                TCSLogWithMark(currentBundle.bundlePath)
                if currentBundle.bundlePath.contains("XCreds") {
                    TCSLogWithMark()
                    let loadPageURL = currentBundle.url(forResource: "loadpage", withExtension: "html")
                    TCSLogWithMark(loadPageURL?.debugDescription ?? "none")
                    self.webView.load(URLRequest(url:loadPageURL!))
                    break

                }
            }
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
    func tokensUpdated(tokens: Tokens){
//to be overridden by superclasses
    }
}

extension WebViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        TCSLogWithMark("DecidePolicyFor: \(navigationAction.request.url?.absoluteString ?? "None")")


        let idpHostName = UserDefaults.standard.value(forKey: PrefKeys.idpHostName.rawValue)
        let customPasswordElementID = UserDefaults.standard.value(forKey: PrefKeys.customPasswordElementID.rawValue) as? String ?? "passwordInput"
        // if it's a POST let's see what we're posting...
        if navigationAction.request.httpMethod == "POST" {
            TCSLogWithMark("POST")
            if let idpHostName = idpHostName as? String, navigationAction.request.url?.host == idpHostName {
                TCSLogWithMark(idpHostName.sanitized())

                let javaScript = "document.getElementById('\(customPasswordElementID.sanitized())').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                    if let rawPass = response as? String {
                        self.password=rawPass
                    }
                    else {
                        TCSLogWithMark("No password found")
                        return
                    }
                })

            }

            // Azure snarfing
            else if navigationAction.request.url?.host == "login.microsoftonline.com" {
                TCSLogWithMark("Azure")

                var javaScript = "document.getElementById('i0118').value"
                ///passwordInput
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                    if let rawPass = response as? String {
                        self.password=rawPass
                    }
                    else {
                        TCSLogWithMark("No password found")

                    }
                })

                javaScript = "document.getElementById('confirmNewPassword').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                    if let rawPass = response as? String {
                        self.password=rawPass
                    }
                    else {
                        TCSLogWithMark("No confirmNewPassword found")
                    }
                })
            } else if navigationAction.request.url?.host == "accounts.google.com" {
                // Google snarfing
                TCSLogWithMark("Google")
                let javaScript = "document.querySelector('input[type=password]').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                    if let rawPass = response as? String {
                        self.password=rawPass
                    }
                    else {
                        TCSLogWithMark("No password found")

                    }


                })
            } else if navigationAction.request.url?.path.contains("verify") ?? false {
                // maybe OneLogin?
                TCSLogWithMark("Other Provider")

                let javaScript = "document.getElementById('input8').value"
                webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                })
            }
            else {
                TCSLogWithMark("Unknown Provider")
                TCSLogWithMark(navigationAction.request.url?.path ?? "<<URL EMPTY>>")
            }
        } else if navigationAction.request.httpMethod == "GET" && navigationAction.request.url?.path.contains("token/redirect") ?? false {
            TCSLogWithMark("GET with Token/redirect")
            // for Okta
            let javaScript = "document.getElementById('input74').value"
            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
            })
        }
        else {
            TCSLogWithMark(navigationAction.request.httpMethod ?? "Unknown method")
            TCSLogWithMark("path = \(navigationAction.request.url?.path ?? "no path")");

//            let javaScript = "document.documentElement.outerHTML.toString()"
//            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
//                TCSLogWithMark(response as? String ?? "No HTML")
//            })


        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        TCSLogWithMark(error.localizedDescription)


    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        TCSLogWithMark(error.localizedDescription)
    }
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        TCSLogWithMark("WebDel:: Did Receive Redirect for: \(webView.url?.absoluteString ?? "None")")

         let redirectURI = TokenManager.shared.oidc().redirectURI
            TCSLogWithMark("redirectURI: \(redirectURI)")
            TCSLogWithMark("URL: \(webView.url?.absoluteString ?? "NONE")")
            if (webView.url?.absoluteString.starts(with: (redirectURI))) ?? false {
                var code = ""
                let fullCommand = webView.url?.absoluteString ?? ""
                let pathParts = fullCommand.components(separatedBy: "&")
                for part in pathParts {
                    if part.contains("code=") {
                        code = part.replacingOccurrences(of: redirectURI + "?" , with: "").replacingOccurrences(of: "code=", with: "")
                        TokenManager.shared.oidc().getToken(code: code)
                        return
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
        TCSLogWithMark("authFailure: \(message)")
        NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:[:])

    }

    func tokenResponse(tokens: OIDCLiteTokenResponse) {
        TCSLogWithMark("tokenResponse")
        RunLoop.main.perform {
            if let password = self.password {
                TCSLogWithMark("password received")
                let returnTokens = Tokens(password: password, accessToken: tokens.accessToken ?? "", idToken: tokens.idToken ?? "", refreshToken: tokens.refreshToken ?? "")
                self.tokensUpdated(tokens: returnTokens)
                NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:["tokens":returnTokens]

                )

            }
            else {
                TCSLogWithMark("no password!")
                NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:[:])

            }
        }
    }
}
extension String {
    func sanitized() -> String {
        // see for ressoning on charachrer sets https://superuser.com/a/358861
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>| ")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)

        return self
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
    }

    mutating func sanitize() -> Void {
        self = self.sanitized()
    }




}
