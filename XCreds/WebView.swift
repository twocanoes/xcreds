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
            break
            let allBundles = Bundle.allBundles
            for currentBundle in allBundles {
                TCSLogWithMark(currentBundle.bundlePath)
                if currentBundle.bundlePath.contains("XCreds") {
                    TCSLogWithMark()
                    let loadPageURL = currentBundle.url(forResource: "errorpage", withExtension: "html")
                    if let loadPageURL = loadPageURL {
                        TCSLogWithMark(loadPageURL.debugDescription ?? "none")
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
                    TCSLogWithMark(currentBundle.bundlePath)
                    TCSLogWithMark()
                    let loadPageURL = currentBundle.url(forResource: "loadpage", withExtension: "html")
                    TCSLogWithMark(loadPageURL.debugDescription ?? "none")
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

        let idpHostName = UserDefaults.standard.value(forKey: PrefKeys.idpHostName.rawValue)
        var idpHostNames = UserDefaults.standard.value(forKey: PrefKeys.idpHostNames.rawValue)

        if idpHostNames == nil && idpHostName != nil {
            idpHostNames=[idpHostName]
        }
        let passwordElementID:String? = UserDefaults.standard.value(forKey: PrefKeys.passwordElementID.rawValue) as? String
        let shouldFindPasswordElement:Bool? = UserDefaults.standard.bool(forKey: PrefKeys.shouldFindPasswordElement.rawValue)

        webView.evaluateJavaScript("result", completionHandler: { response, error in
            if error != nil {
                TCSLogWithMark(error?.localizedDescription ?? "unknown error")
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

        let pathURL = Bundle.main.url(forResource: "get_pw", withExtension: "js")
        guard let pathURL = pathURL else {
            return
        }

        let javascript = try? String(contentsOf: pathURL, encoding: .utf8)

        guard let javascript = javascript else {
            return
        }

        webView.evaluateJavaScript(javascript, completionHandler: { response, error in
            if (error != nil){
                TCSLogWithMark(error?.localizedDescription ?? "empty error")
            }
        })

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
