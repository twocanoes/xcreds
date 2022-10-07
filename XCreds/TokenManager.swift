//
//  TokenManager.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//
import Foundation
import OIDCLite

struct RefreshTokenResponse: Codable {
    let accessToken, expiresIn, expiresOn, refreshToken, extExpiresIn,tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case expiresOn = "expires_on"
        case refreshToken = "refresh_token"
        case extExpiresIn = "ext_expires_in"
        case tokenType = "token_type"
    }
}

struct IDToken:Codable {
    let iss,sub,aud:String
    let iat, exp:Int
    let email:String?
    let unique_name, given_name,family_name,name:String?

    enum CodingKeys: String, CodingKey {
        case iss,sub,aud,name,given_name,family_name,email,iat,exp, unique_name

    }
}
class TokenManager {

    static let shared = TokenManager()

    let defaults = UserDefaults.standard
    var timer: Timer?
    private var oidcLocal:OIDCLite?
    func oidc() -> OIDCLite {
        var scopes: [String]?
        var additionalParameters:[String:String]? = nil
        var clientSecret:String?

        if let oidcPrivate = oidcLocal {
            oidcPrivate.getEndpoints()

            return oidcPrivate
        }
        if let clientSecretRaw = UserDefaults.standard.string(forKey: PrefKeys.clientSecret.rawValue),
           clientSecretRaw != "" {
            clientSecret = clientSecretRaw
        }
        if let scopesRaw = UserDefaults.standard.string(forKey: PrefKeys.scopes.rawValue) {
            scopes = scopesRaw.components(separatedBy: " ")
        }
        //
        if UserDefaults.standard.bool(forKey: PrefKeys.shouldSetGoogleAccessTypeToOffline.rawValue) == true {

            additionalParameters = ["access_type":"offline"]
        }

        let oidcLite = OIDCLite(discoveryURL: UserDefaults.standard.string(forKey: PrefKeys.discoveryURL.rawValue) ?? "NONE", clientID: UserDefaults.standard.string(forKey: PrefKeys.clientID.rawValue) ?? "NONE", clientSecret: clientSecret, redirectURI: UserDefaults.standard.string(forKey: PrefKeys.redirectURI.rawValue), scopes: scopes, additionalParameters:additionalParameters )
        oidcLite.getEndpoints()
        oidcLocal = oidcLite
        return oidcLite


    }

    func saveTokensToKeychain(tokens:Tokens, setACL:Bool=false, password:String?=nil) -> Bool {
        let keychainUtil = KeychainUtil()

        if tokens.accessToken.count>0{
            TCSLogWithMark("Saving Access Token")
            if  keychainUtil.updatePassword(PrefKeys.accessToken.rawValue, pass: tokens.accessToken,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogWithMark("Error Updating Access Token")

                return false
            }

        }
        if tokens.idToken.count>0{
            TCSLogWithMark("Saving idToken Token")
            if  keychainUtil.updatePassword(PrefKeys.idToken.rawValue, pass: tokens.idToken, shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogWithMark("Error Updating idToken Token")

                return false
            }
        }


        if tokens.refreshToken.count>0 {
            TCSLogWithMark("Saving refresh Token")

            if keychainUtil.updatePassword(PrefKeys.refreshToken.rawValue, pass: tokens.refreshToken,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogWithMark("Error Updating refreshToken Token")

                return false
            }
        }

        let cloudPassword = tokens.password
        
        if cloudPassword.count>0 {
            TCSLogWithMark("Saving cloud password")

            if keychainUtil.updatePassword(PrefKeys.password.rawValue, pass: tokens.password,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogWithMark("Error Updating password")

                return false
            }

        }
        return true
    }
    func tokenEndpoint() -> String? {

        let prefTokenEndpoint = UserDefaults.standard.string(forKey: PrefKeys.tokenEndpoint.rawValue)
        if  prefTokenEndpoint != nil {
            return prefTokenEndpoint
        }


        if let tokenEndpoint = oidc().OIDCTokenEndpoint {
            return tokenEndpoint
        }
        return nil
    }
    func getNewAccessToken(completion:@escaping (_ isSuccessful:Bool,_ hadConnectionError:Bool)->Void) -> Void {


        guard let endpoint = TokenManager.shared.tokenEndpoint(), let url = URL(string: endpoint) else {
            completion(false,true)
            return
        }

        var req = URLRequest(url: url)

        let keychainUtil = KeychainUtil()

        let refreshToken = try? keychainUtil.findPassword(PrefKeys.refreshToken.rawValue)
        let clientID = defaults.string(forKey: PrefKeys.clientID.rawValue)
        let keychainPassword = try? keychainUtil.findPassword(PrefKeys.password.rawValue)

        if let refreshToken = refreshToken, let clientID = clientID, let keychainPassword = keychainPassword {

            var parameters = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(clientID )"
            if let clientSecret = defaults.string(forKey: PrefKeys.clientSecret.rawValue) {
                parameters.append("&client_secret=\(clientSecret)")
            }

            let postData =  parameters.data(using: .utf8)
            req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            req.httpMethod = "POST"
            req.httpBody = postData

            let task = URLSession.shared.dataTask(with: req) { data, response, error in
              guard let data = data else {
                print(String(describing: error))
                  completion(false,true)
                  return
              }
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        let decoder = JSONDecoder()
                        do {

                            let json = try decoder.decode(RefreshTokenResponse.self, from: data)
                            let expirationDate = Date().addingTimeInterval(TimeInterval(Int(json.expiresIn) ?? 0))
                            UserDefaults.standard.set(expirationDate, forKey: PrefKeys.expirationDate.rawValue)

                            let keychainUtil = KeychainUtil()
                            let _ = keychainUtil.updatePassword(PrefKeys.refreshToken.rawValue, pass: json.refreshToken, shouldUpdateACL: true, keychainPassword: keychainPassword)
                            let _ = keychainUtil.updatePassword(PrefKeys.accessToken.rawValue, pass: json.accessToken, shouldUpdateACL:true, keychainPassword: keychainPassword)

                            completion(true,false)

                        }
                        catch {
                            completion(true,false)
                            return
                        }

                    }
                    else {
                        TCSLogWithMark("got status code of \(response.statusCode)")
                        completion(false,false)

                    }
                }
            }

            task.resume()
        }
        else {
            TCSLogWithMark("clientID or refreshToken blank. clientid: \(clientID ?? "empty") refreshtoken:\(refreshToken ?? "empty")")
            completion(false,false)

        }
    }
}

