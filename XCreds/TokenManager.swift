//
//  TokenManager.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//
import Foundation


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

class TokenManager {

    static let shared = TokenManager()

    let defaults = UserDefaults.standard
    var timer: Timer?

    func getNewAccessToken(completion:@escaping (_ isSuccessful:Bool,_ hadConnectionError:Bool)->Void) -> Void {

        guard let url = URL(string: defaults.string(forKey: PrefKeys.tokenEndpoint.rawValue) ?? "") else {
            completion(false,true)
            return
        }

        var req = URLRequest(url: url)

        let keychainUtil = KeychainUtil()

        let refreshToken = try? keychainUtil.findPassword(PrefKeys.refreshToken.rawValue)
        let clientID = defaults.string(forKey: PrefKeys.clientID.rawValue)

        if let refreshToken = refreshToken, let clientID = clientID {

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
                            let _ = keychainUtil.updatePassword(PrefKeys.refreshToken.rawValue, pass: json.refreshToken)
                            let _ = keychainUtil.updatePassword(PrefKeys.accessToken.rawValue, pass: json.accessToken)

                            completion(true,false)

                        }
                        catch {
                            print(String(data: data, encoding: .utf8) as Any)
                            completion(true,false)
                            return
                        }

                    }
                    else {
                        TCSLog("got status code of \(response.statusCode)")
                        completion(false,false)

                    }
                }
            }

            task.resume()
        }
        else {
            TCSLog("clientID or refreshToken blank. clientid: \(clientID ?? "empty") refreshtoken:\(refreshToken ?? "empty")")
            completion(false,false)

        }
    }
}
