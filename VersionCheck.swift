//
//  VersionCheck.swift
//  DFU Blaster Pro
//
//  Created by Timothy Perfitt on 9/26/24.
//

import Foundation

class VersionCheck{
    enum Event:String {
        case checkin
        case usage
    }
    struct VersionInfo: Decodable {

        let product: String?
        let version: String?
        let release_date: String?
    }
    static func reportLicenseUsage(event:Event, usage:Int=1)-> Void {

        let identifier = Bundle.main.bundleIdentifier ?? "Unknown"

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown"


        guard let licenseCheckURL = UserDefaults.standard.string(forKey: "licenseActivityURL"), let url = URL(string:licenseCheckURL) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let check = TCSLicenseCheck()//com.twocanoes.xcreds
        let _ = check.checkLicenseStatus(identifier, withExtension: "")
        let key = check.license.licenseKey ?? "Unlicensed"
        let uniqueID = getSystemUUID() ?? ""


        let json: [String: Any] = ["system_id": uniqueID,
                                   "app_id":identifier,
                                   "version":version,
                                   "license_key":key,
                                   "event":event.rawValue,
                                   "usage":1]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        request.httpBody=jsonData
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

        }
        task.resume()
    }
    static func versionForIdentifier(identifier:String, version:String,completion: @escaping (_ isSuccess:Bool, _ version:String) -> Void){

        guard let versionCheckURLString = UserDefaults.standard.string(forKey: "versionCheckURL"), let url = URL(string:versionCheckURLString) else {
            completion(false, "")
            return

        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
    static func getSystemUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard let rawUUID = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        else { return nil }
        let uuid = rawUUID.takeUnretainedValue()
        if let result = uuid as? String {
            return result
        }
        return nil
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
