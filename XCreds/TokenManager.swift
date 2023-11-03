//
//  TokenManager.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//
import Foundation
import OIDCLite

@propertyWrapper
struct IntConvertible: Decodable {
    var wrappedValue: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = 0
        if let intValue = try? container.decode(Int.self) {
            wrappedValue = intValue
        } else if  let stringValue = try? container.decode(String.self), let intValue = Int(stringValue) {
            wrappedValue = intValue
        }
    }
}

struct RefreshTokenResponse: Decodable {
    let accessToken, refreshToken, tokenType: String
    @IntConvertible var expiresIn: Int
    let expiresOn, extExpiresIn: String?

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
        return oidcLite


    }

    func saveTokensToKeychain(creds:Creds, setACL:Bool=false, password:String?=nil) -> Bool {
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


        
        if creds.password.count>0 {
            TCSLogWithMark("Saving cloud password")

            if keychainUtil.updatePassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue, pass: creds.password,shouldUpdateACL: setACL, keychainPassword:password) == false {
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

    func getNewAccessToken(completion:@escaping (_ isSuccessful:Bool,_ hadConnectionError:Bool)->Void) -> Void {
        TCSLogWithMark()
        guard let endpoint = TokenManager.shared.tokenEndpoint(), let url = URL(string: endpoint) else {
            TCSLogWithMark()
            completion(false,true)
            return
        }

        var req = URLRequest(url: url)

        let keychainUtil = KeychainUtil()
        TCSLogWithMark()
        let refreshAccountAndToken = try? keychainUtil.findPassword(serviceName: "xcreds ".appending(PrefKeys.refreshToken.rawValue),accountName:PrefKeys.refreshToken.rawValue)

        let clientID = defaults.string(forKey: PrefKeys.clientID.rawValue)
        let keychainAccountAndPassword = try? keychainUtil.findPassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue)
        
        func handleIdpResponse(data: Data?, response: URLResponse?, error: Error?, keychainPassword: String) {
            guard let data = data else {
                print(String(describing: error))
                if let error = error {
                    print(error.localizedDescription)
                }
                completion(false,true)
                return
            }
              if let response = response as? HTTPURLResponse {
                  if response.statusCode == 200 {
                      let decoder = JSONDecoder()
                      do {

                          let json = try decoder.decode(RefreshTokenResponse.self, from: data)
                          let expirationDate = Date().addingTimeInterval(TimeInterval(json.expiresIn))
                          DefaultsOverride.standardOverride.set(expirationDate, forKey: PrefKeys.expirationDate.rawValue)

                          let keychainUtil = KeychainUtil()
                          let _ = keychainUtil.updatePassword(serviceName: "xcreds",accountName:PrefKeys.refreshToken.rawValue, pass: json.refreshToken, shouldUpdateACL: true, keychainPassword: keychainPassword)
                          let _ = keychainUtil.updatePassword(serviceName: "xcreds",accountName:PrefKeys.accessToken.rawValue, pass: json.accessToken, shouldUpdateACL:true, keychainPassword: keychainPassword)
                          TCSLogWithMark("Credentials are current.")
                          completion(true,false)

                      }
                      catch {
                          TCSLogWithMark("Credentials are current, but failed to decode response")
                          completion(true,false)
                          return
                      }

                  }
                  else {
                      TCSLogErrorWithMark("Failed to verify credentials status code returned: \(response.statusCode):\(response)")
                      completion(false,false)

                  }
              }
        }

        TCSLogWithMark()
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldVerifyPasswordWithRopg.rawValue) == true, let keychainAccountAndPassword = keychainAccountAndPassword, let keychainPassword = keychainAccountAndPassword.1, let ropgClientSecret = DefaultsOverride.standardOverride.string(forKey: PrefKeys.ropgClientSecret.rawValue), let ropgClientID = DefaultsOverride.standardOverride.string(forKey: PrefKeys.ropgClientID.rawValue) {
            TCSLogWithMark("Checking credentials in keychain using ROPG")
            let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
            guard let userName = currentUser?.recordName else {
                completion(false,true)
                return
            }
            let loginString = "\(ropgClientID):\(ropgClientSecret)"
            guard let loginData = loginString.data(using: .utf8) else {
                completion(false,true)
                return
            }
            let base64LoginString = loginData.base64EncodedString()
            let urlEncodedUsername = userName.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed)
            let urlEncodedPassword = keychainPassword.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed)
            guard let urlEncodedPassword = urlEncodedPassword, let urlEncodedUsername = urlEncodedUsername else {
                completion(false,true)
                return
            }
            let parameters = "grant_type=password&username=\(urlEncodedUsername)&password=\(urlEncodedPassword)&scope=offline_access"

            let postData =  parameters.data(using: .utf8)
            req.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
            req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.addValue("application/json", forHTTPHeaderField: "Accept")
            

            req.httpMethod = "POST"
            req.httpBody = postData

            let task = URLSession.shared.dataTask(with: req) { data, response, error in
                handleIdpResponse(data: data, response: response, error: error, keychainPassword: keychainPassword)
            }

            task.resume()
        }
        else if let refreshAccountAndToken = refreshAccountAndToken, let refreshToken = refreshAccountAndToken.1, let clientID = clientID, let keychainAccountAndPassword = keychainAccountAndPassword, let keychainPassword = keychainAccountAndPassword.1 {
            TCSLogWithMark("Checking credentials in keychain using refresh token")
            var parameters = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(clientID )"
            if let clientSecret = defaults.string(forKey: PrefKeys.clientSecret.rawValue) {
                parameters.append("&client_secret=\(clientSecret)")
            }

            let postData =  parameters.data(using: .utf8)
            req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            req.httpMethod = "POST"
            req.httpBody = postData

            let task = URLSession.shared.dataTask(with: req) { data, response, error in
                handleIdpResponse(data: data, response: response, error: error, keychainPassword: keychainPassword)
            }

            task.resume()
        }
        else {
            TCSLogWithMark("clientID or refreshToken blank. clientid: \(clientID ?? "empty") refreshtoken:\(refreshAccountAndToken?.1 ?? "empty")")
            completion(false,false)

        }
    }
}

