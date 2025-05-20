//
//  VersionCheck.swift
//  DFU Blaster Pro
//
//  Created by Timothy Perfitt on 9/26/24.
//

import Foundation

class VersionCheck{
    struct VersionInfo: Decodable {

        let product: String?
        let version: String?
        let release_date: String?
    }
    static func versionForIdentifier(identifier:String, version:String,completion: @escaping (_ isSuccess:Bool, _ version:String) -> Void){

        guard let versionCheckURLString = UserDefaults.standard.string(forKey: "versionCheckURL"), let url = URL(string:versionCheckURLString) else {
            completion(false, "")
            return

        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let check = TCSLicenseCheck()
        let _ = check.checkLicenseStatus(identifier, withExtension: "")
        let key = check.license.licenseKey
        let uniqueID = UserDefaults.standard.string(forKey: "uniqueID") ?? UUID().uuidString

        UserDefaults.standard.set(uniqueID, forKey: "uniqueID")

        request.setValue(uniqueID, forHTTPHeaderField: "TCS-INFO-UNIQUE-ID")

        request.setValue(identifier, forHTTPHeaderField: "TCS-APP-IDENTIFIER")

        request.setValue(version, forHTTPHeaderField: "TCS-APP-VERSION")

        if let key = key {
            request.setValue(key, forHTTPHeaderField: "TCS-INFO-KEY")
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, "")
                return
            }
            let response = response as! HTTPURLResponse
            let status = response.statusCode
            guard (200...299).contains(status) else {
                completion(false, "")
                return
            }
            let json = JSONDecoder.init()


            let versionInfo = try? json.decode([String:VersionInfo].self, from: data)

            guard let versionInfo = versionInfo,
                    let product = versionInfo[identifier],
                  let version = product.version else {
                      completion(false, "" )
                return
            }
            completion(true,version )
        }
        task.resume()
    }
}
extension Bundle {

    func urlString(key:String) -> String? {
        if let infoDictionary = self.infoDictionary {
            let supportURLs = infoDictionary["Support URLs"] as? NSDictionary
            if let supportURLs = supportURLs{

                let infoURLString = supportURLs[key] as? String
                return infoURLString
            }
        }
        return nil
    }
}
