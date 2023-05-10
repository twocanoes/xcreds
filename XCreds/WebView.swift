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


        let licenseState = LicenseChecker().currentLicenseState()
        if let refreshTitleTextField = refreshTitleTextField {
            refreshTitleTextField.isHidden = !UserDefaults.standard.bool(forKey: PrefKeys.shouldShowRefreshBanner.rawValue)
        }

        webView.navigationDelegate = self
        TokenManager.shared.oidc().delegate = self
        clearCookies()

        switch licenseState {

        case .valid, .trial(_):
            break
        case .invalid,.trialExpired, .expired:
            let allBundles = Bundle.allBundles
            for currentBundle in allBundles {
                if currentBundle.bundlePath.contains("XCreds") {
                    let loadPageURL = currentBundle.url(forResource: "errorpage", withExtension: "html")
                    if let loadPageURL = loadPageURL {
                        self.webView.load(URLRequest(url:loadPageURL))
                    }
                    break
                }
            }
            return

        }
         if let url = TokenManager.shared.oidc().createLoginURL() {
            TCSLogWithMark()
            self.webView.load(URLRequest(url: url))
        }
        else {
            let allBundles = Bundle.allBundles
            for currentBundle in allBundles {
                if currentBundle.bundlePath.contains("XCreds") {
                    let loadPageURL = currentBundle.url(forResource: "loadpage", withExtension: "html")
                    if let loadPageURL = loadPageURL {
                        self.webView.load(URLRequest(url:loadPageURL))
                    }
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
    }
}

extension WebViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let idpHostName = UserDefaults.standard.value(forKey: PrefKeys.idpHostName.rawValue)
        var idpHostNames = UserDefaults.standard.value(forKey: PrefKeys.idpHostNames.rawValue)

        if idpHostNames == nil && idpHostName != nil {
            idpHostNames=[idpHostName]
        }
        let passwordElementID:String? = UserDefaults.standard.value(forKey: PrefKeys.passwordElementID.rawValue) as? String
        let shouldFindPasswordElement:Bool? = UserDefaults.standard.bool(forKey: PrefKeys.shouldFindPasswordElement.rawValue)

        TCSLogWithMark("inserting javascript to get password")
        webView.evaluateJavaScript("result", completionHandler: { response, error in
            if error != nil {
//                TCSLogWithMark(error?.localizedDescription ?? "unknown error")
            }
            else {
                if let responseDict = response as? NSDictionary, let ids = responseDict["ids"] as? Array<String>, let passwords = responseDict["passwords"] as? Array<String>, passwords.count>0 {

                    TCSLogWithMark("found password elements with ids:\(ids)")

                    guard let host = navigationAction.request.url?.host else {

                        return
                    }
                    var foundHostname = ""
                    if  let idpHostNames = idpHostNames as? Array<String?>,
                        idpHostNames.contains(host) {
                        foundHostname=host

                    }
                    else if ["login.microsoftonline.com", "login.live.com", "accounts.google.com"].contains(host) || host.contains("okta.com"){
                        foundHostname=host

                    }
                    else {
                        TCSLogWithMark("hostname (\(host)) not matched so not looking for password")
                        return
                    }

                    TCSLogWithMark("host matches custom idpHostName \(foundHostname)")

                    // we have exactly 1 password and it matches what was specified in prefs.
                    if let passwordElementID = passwordElementID, ids.count==1, ids[0]==passwordElementID, passwords.count==1 {
                        TCSLogWithMark("passwordElementID is \(passwordElementID)")
                        TCSLogWithMark("========= password set===========")
                        self.password=passwords[0]

                    }
                    else if passwords.count==3, passwords[1]==passwords[2] {
                        TCSLogWithMark("found 3 password fields. so it is a reset password situation")
                        TCSLogWithMark("========= password set===========")
                        self.password=passwords[2]

                    }
                    //
                    if shouldFindPasswordElement == true {
                        if passwords.count==1 {
                            TCSLogWithMark("found 1 password field. setting")
                            TCSLogWithMark("========= password set===========")
                            self.password=passwords[0]
                        }
                        else {
                            TCSLogWithMark("password not set. Found: \(ids)")
                            return

                        }
                    }
                    else {
                        TCSLogWithMark("password not captured")
                    } 
                }
            }
        })
        decisionHandler(.allow)

    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //this inserts javascript to copy passwords to a variable. Sometimes the
        //div gets removed before we can evaluate it so this helps. It works by
        // attaching to keydown. At each keydown, it attaches to password elements
        // for keyup. When a key is released, it copies all the passwords to an array
        // to be read later.

        TCSLogWithMark("adding listener for password")
        var pathURL:URL?
        let allBundles = Bundle.allBundles
        for currentBundle in allBundles {
            if currentBundle.bundlePath.contains("XCreds") {
                TCSLogWithMark()
                pathURL = currentBundle.url(forResource: "get_pw", withExtension: "js")
                break
            }
        }

        guard let pathURL = pathURL else {
            TCSLogWithMark("get_pw.js not found")
            return
        }

        let javascript = try? String(contentsOf: pathURL, encoding: .utf8)

        guard let javascript = javascript else {
            return
        }

        webView.evaluateJavaScript(javascript, completionHandler: { response, error in
            if (error != nil){
//                TCSLogWithMark(error?.localizedDescription ?? "empty error")
            }
            else {
                TCSLogWithMark("inserted javascript for password setup")
            }
        })

    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {


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
