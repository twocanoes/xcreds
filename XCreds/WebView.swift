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

    @IBOutlet weak var refreshTitleTextField: NSTextField?
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var cancelButton: NSButton!

    var password:String?
    func loadPage() {


        if let refreshTitleTextField = refreshTitleTextField {
            refreshTitleTextField.isHidden = !UserDefaults.standard.bool(forKey: PrefKeys.shouldShowRefreshBanner.rawValue)
        }

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
    func tokensUpdated(tokens: Creds){
//to be overridden by superclasses
/*
        var username:String
        let defaultsUsername = UserDefaults.standard.string(forKey: PrefKeys.username.rawValue)

        guard let idToken = tokens.idToken else {
            TCSLogWithMark("invalid idToken")

            return
        }

        let array = idToken.components(separatedBy: ".")

        if array.count != 3 {
            TCSLogWithMark("idToken is invalid")
        }
        let body = array[1]
        guard let data = base64UrlDecode(value:body ) else {
            TCSLogWithMark("error decoding id token base64")
            return
        }
        let decoder = JSONDecoder()
        var idTokenObject:IDToken
        do {
            idTokenObject = try decoder.decode(IDToken.self, from: data)

        }
        catch {
            TCSLogWithMark("error decoding idtoken::")
            TCSLogWithMark("Token:\(body)")
            return

        }

        let idTokenInfo = jwtDecode(value: idToken)  //dictionary for mappnigs

        // username static map
        if let defaultsUsername = defaultsUsername {
            username = defaultsUsername
        }
        else if let idTokenInfo = idTokenInfo, let mapKey = UserDefaults.standard.object(forKey: "map_username")  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
//we have a mapping for username, so use that.

            username = mapValue
            TCSLogWithMark("mapped username found: \(username)")

        }
        else {
            var emailString:String

            if let email = idTokenObject.email  {
                emailString=email.lowercased()
            }
            else if let uniqueName=idTokenObject.unique_name {
                emailString=uniqueName
            }

            else {
                TCSLogWithMark("no username found. Using sub.")
                emailString=idTokenObject.sub
            }
            guard let tUsername = emailString.components(separatedBy: "@").first?.lowercased() else {
                TCSLogWithMark("email address invalid")
                return

            }

            TCSLogWithMark("username found: \(tUsername)")
            username = tUsername
        }

        //full name
        TCSLogWithMark("checking map_fullname")

        if let idTokenInfo = idTokenInfo, let mapKey = UserDefaults.standard.object(forKey: "map_fullname")  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
//we have a mapping so use that.
            TCSLogWithMark("full name mapped to: \(mapKey)")


        }

        else if let firstName = idTokenObject.given_name, let lastName = idTokenObject.family_name {
            TCSLogWithMark("firstName: \(firstName)")
            TCSLogWithMark("lastName: \(lastName)")

        }

        //first name
        if let idTokenInfo = idTokenInfo, let mapKey = UserDefaults.standard.object(forKey: "map_firstname")  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
//we have a mapping for username, so use that.
            TCSLogWithMark("first name mapped to: \(mapKey)")

        }

       else if let firstName = idTokenObject.given_name {
           TCSLogWithMark("firstName from token: \(firstName)")


        }
 */
    }
}

extension WebViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        TCSLogWithMark("DecidePolicyFor: \(navigationAction.request.url?.absoluteString ?? "None")")

        let idpHostName = UserDefaults.standard.value(forKey: PrefKeys.idpHostName.rawValue)
        var idpHostNames = UserDefaults.standard.value(forKey: PrefKeys.idpHostNames.rawValue)

        if idpHostNames == nil && idpHostName != nil {
            idpHostNames=[idpHostName]
        }
        let passwordElementID:String? = UserDefaults.standard.value(forKey: PrefKeys.passwordElementID.rawValue) as? String
        if let idpHostNames = idpHostNames as? Array<String?>, idpHostNames.contains(navigationAction.request.url?.host), let passwordElementID = passwordElementID {
            TCSLogWithMark("host matches custom idpHostName")
            TCSLogWithMark("passwordElementID is \(passwordElementID)")

            TCSLogWithMark("inserting javascript to get password")

            let javaScript = "document.getElementById('\(passwordElementID.sanitized())').value"
            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                if let rawPass = response as? String, rawPass != "" {
                    TCSLogWithMark("========= password set===========")
                    self.password=rawPass
                }
                else {
                    TCSLogWithMark("password not captured")
                    return
                }
            })

        }
        // Azure snarfing
        else if ["login.microsoftonline.com", "login.live.com"].contains(navigationAction.request.url?.host) {
            TCSLogWithMark("Azure")

            var javaScript = "document.getElementById('i0118').value"
            if  let passwordElementID = passwordElementID {
                javaScript = "document.getElementById('\(passwordElementID.sanitized())').value"
            }
            ///passwordInput
            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                if let rawPass = response as? String {
                    TCSLogWithMark("========= password set===========")

                    self.password=rawPass
                }
                else {
                    TCSLogWithMark("password not captured")

                }
            })

//            javaScript = "document.getElementById('confirmNewPassword').value"
//            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
//                if let rawPass = response as? String {
//                    self.password=rawPass
//                }
//            })
        } else if navigationAction.request.url?.host == "accounts.google.com" {
            // Google snarfing
            TCSLogWithMark("Google")
            let javaScript = "document.querySelector('input[type=password]').value"
            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
                if let rawPass = response as? String {
                    TCSLogWithMark("========= password set===========")

                    self.password=rawPass
                }
                else {
                    TCSLogWithMark("password not captured")
                }
            })
        } else if navigationAction.request.url?.path.contains("verify") ?? false {
            // maybe OneLogin?
            TCSLogWithMark("Other Provider")

            let javaScript = "document.getElementById('input8').value"
            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in
            })
        }
        else if navigationAction.request.url?.host?.contains("okta.com") ?? false ||
                    navigationAction.request.url?.host?.contains("duosecurity.com") ?? false
        {
            TCSLogWithMark("okta")
            // for Okta
            var javaScript = "document.getElementById('okta-signin-password').value"
            if  let passwordElementID = passwordElementID {
                TCSLogWithMark("setting passwordElementID to \(passwordElementID)")

                javaScript = "document.getElementById('\(passwordElementID.sanitized())').value"
                TCSLogWithMark("javascript: \(javaScript)")

            }
            webView.evaluateJavaScript(javaScript, completionHandler: { response, error in

                TCSLogWithMark(error?.localizedDescription ?? "no error.localizedDescription")

                if let rawPass = response as? String, rawPass != "" {
                    TCSLogWithMark("========= password set===========")
                    self.password=rawPass
                }
            })

        }
        else {
            TCSLogWithMark("Unknown Provider")
            TCSLogWithMark(navigationAction.request.url?.path ?? "<<URL EMPTY>>")
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
                TCSLogWithMark("got redirect URI match. separating URL")
                var code = ""
                let fullCommand = webView.url?.absoluteString ?? ""
                let pathParts = fullCommand.components(separatedBy: "&")
                for part in pathParts {
                    if part.contains("code=") {
                        TCSLogWithMark("found code=. cleaning up.")

                        code = part.replacingOccurrences(of: redirectURI + "?" , with: "").replacingOccurrences(of: "code=", with: "")
                        TCSLogWithMark("getting tokens")

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
        TCSLogWithMark("======== tokenResponse =========")
        RunLoop.main.perform {
            if let password = self.password {
                TCSLogWithMark("----- Password was set")
                let xcredCreds = Creds(password: password, tokens: tokens)
                self.tokensUpdated(tokens: xcredCreds)

                NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:["tokens":xcredCreds]
                )
            }
            else {
                TCSLogWithMark("----- password was not set")
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
