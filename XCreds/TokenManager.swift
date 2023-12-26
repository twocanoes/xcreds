//
//  TokenManager.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//
import Foundation
import OIDCLite

struct IDToken:Codable {
    let iss,sub,aud:String
    let iat, exp:Int
    let email:String?
    let unique_name, given_name,family_name,name:String?

    enum CodingKeys: String, CodingKey {
        case iss,sub,aud,name,given_name,family_name,email,iat,exp, unique_name

    }
}

protocol TokenManagerFeedbackDelegate {
    func tokenError(_ err:String)
    func credentialsUpdated(_ credentials:Creds)

}
class TokenManager:DSQueryable, OIDCLiteDelegate {
    func authFailure(message: String) {

    }

    func tokenResponse(tokens: OIDCLite.TokenResponse) {
        
        TCSLogWithMark("======== tokenResponse =========")
        
        RunLoop.main.perform {
            //            if let password = self.password {
            TCSLogWithMark("----- Password was set")
            let xcredCreds = Creds(password: nil, tokens: tokens)
            self.feedbackDelegate?.credentialsUpdated(xcredCreds)
            //TODO: post this?
            NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:["tokens":xcredCreds]
            )
//            }
//            else {
//                TCSLogWithMark("----- password was not set")
//                NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:[:])
//                self.showErrorMessageAndDeny("The password was not set. Please check settings and verify passwordless sign-in was not used.")
//            }
        }
    }
    var feedbackDelegate:TokenManagerFeedbackDelegate?
    let defaults = DefaultsOverride.standard
    private var oidcLocal:OIDCLite?
    func oidc() -> OIDCLite {
        var scopes: [String]?
        var additionalParameters:[String:String]? = nil
        var clientSecret:String?

        if let oidcPrivate = oidcLocal {
            oidcPrivate.getEndpoints()

            return oidcPrivate
        }
        if let clientSecretRaw = DefaultsOverride.standardOverride.string(forKey: PrefKeys.clientSecret.rawValue),
           clientSecretRaw != "" {
            clientSecret = clientSecretRaw
        }
        if let scopesRaw = DefaultsOverride.standardOverride.string(forKey: PrefKeys.scopes.rawValue) {
            scopes = scopesRaw.components(separatedBy: " ")
        }
        //
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldSetGoogleAccessTypeToOffline.rawValue) == true {

            additionalParameters = ["access_type":"offline"]
        }

        let oidcLite = OIDCLite(discoveryURL: DefaultsOverride.standardOverride.string(forKey: PrefKeys.discoveryURL.rawValue) ?? "NONE", clientID: DefaultsOverride.standardOverride.string(forKey: PrefKeys.clientID.rawValue) ?? "NONE", clientSecret: clientSecret, redirectURI: DefaultsOverride.standardOverride.string(forKey: PrefKeys.redirectURI.rawValue), scopes: scopes, additionalParameters:additionalParameters )
        oidcLite.getEndpoints()
        oidcLocal = oidcLite
        oidcLite.delegate=self
        return oidcLite


    }

    static func saveTokensToKeychain(creds:Creds, setACL:Bool=false, password:String?=nil) -> Bool {
        let keychainUtil = KeychainUtil()

        if let accessToken = creds.accessToken, accessToken.count>0{
            TCSLogWithMark("Saving Access Token")
            if  keychainUtil.updatePassword(serviceName: "xcreds ".appending(PrefKeys.accessToken.rawValue),accountName:PrefKeys.accessToken.rawValue, pass: accessToken,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating Access Token")

                return false
            }

        }
        if let idToken = creds.idToken, idToken.count>0{
            TCSLogWithMark("Saving idToken Token")
            if  keychainUtil.updatePassword(serviceName: "xcreds ".appending(PrefKeys.idToken.rawValue),accountName:PrefKeys.idToken.rawValue, pass: idToken, shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating idToken Token")

                return false
            }
        }


        if let refreshToken = creds.refreshToken, refreshToken.count>0 {
            TCSLogWithMark("Saving refresh Token")

            if keychainUtil.updatePassword(serviceName: "xcreds ".appending(PrefKeys.refreshToken.rawValue),accountName:PrefKeys.refreshToken.rawValue, pass: refreshToken,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating refreshToken Token")

                return false
            }
        }


        
        if let password = password, password.count>0 {
            TCSLogWithMark("Saving cloud password")

            if keychainUtil.updatePassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue, pass: password,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating password")

                return false
            }

        }
        return true
    }
   
   

    func tokenEndpoint() -> String? {

        let prefTokenEndpoint = DefaultsOverride.standardOverride.string(forKey: PrefKeys.tokenEndpoint.rawValue)
        if  prefTokenEndpoint != nil {
            return prefTokenEndpoint
        }


        if let tokenEndpoint = oidc().OIDCTokenEndpoint {
            return tokenEndpoint
        }
        return nil
    }

    func getNewAccessToken(completion:@escaping (_ res:OIDCLiteTokenResult)->Void) -> Void {
        TCSLogWithMark()
        guard let endpoint = tokenEndpoint(), let url = URL(string: endpoint) else {
            TCSLogWithMark()
            completion(.error("bad setup for endpoint"))
            return
        }

        let keychainUtil = KeychainUtil()
        TCSLogWithMark()
        let refreshAccountAndToken = try? keychainUtil.findPassword(serviceName: "xcreds ".appending(PrefKeys.refreshToken.rawValue),accountName:PrefKeys.refreshToken.rawValue)

        let clientID = defaults.string(forKey: PrefKeys.clientID.rawValue)
        let keychainAccountAndPassword = try? keychainUtil.findPassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue)
        

        TCSLogWithMark()
        if 
            let keychainAccountAndPassword = keychainAccountAndPassword,
           DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldVerifyPasswordWithRopg.rawValue) == true,

            let keychainPassword = keychainAccountAndPassword.1,
            let ropgClientID = DefaultsOverride.standardOverride.string(forKey: PrefKeys.clientID.rawValue) {
            let ropgClientSecret = DefaultsOverride.standardOverride.string(forKey: PrefKeys.clientSecret.rawValue)
            TCSLogWithMark("Checking credentials in keychain using ROPG")
            let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
            guard let userNames = try? currentUser?.values(forAttribute: "dsAttrTypeNative:_xcreds_oidc_username") as? [String], userNames.count>0 else {
                completion(.error("no username for oidc config"))
                return
            }
            oidc().requestTokenWithROPG(ropgClientID: ropgClientID, ropgClientSecret: ropgClientSecret, userName: userNames[0],keychainPassword: keychainPassword, url: url)

            

        }
        else if let refreshAccountAndToken = refreshAccountAndToken, let refreshToken = refreshAccountAndToken.1 {

            oidcLocal?.refreshTokens(refreshToken)
//            TCSLogWithMark("Checking credentials in keychain using refresh token")
//            var parameters = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(clientID )"
//            if let clientSecret = defaults.string(forKey: PrefKeys.clientSecret.rawValue) {
//                parameters.append("&client_secret=\(clientSecret)")
//            }
//
//            let postData =  parameters.data(using: .utf8)
//            req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//
//            req.httpMethod = "POST"
//            req.httpBody = postData
//
//            let task = URLSession.shared.dataTask(with: req) { data, response, error in
//                self.handleIdpResponse(data: data, response: response, error: error, keychainPassword: keychainPassword, completion: completion)
//            }
//
//            task.resume()
        }
        else {
            TCSLogWithMark("clientID or refreshToken blank. clientid: \(clientID ?? "empty") refreshtoken:\(refreshAccountAndToken?.1 ?? "empty")")
            completion(.success)

        }
    }

}

