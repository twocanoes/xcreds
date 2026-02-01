//
//  Utils.swift
//  Scissors
//
//  Created by Timothy Perfitt on 4/4/24.
//

import Foundation

let kService = "Cookie Cache"

func combineCookies(cookies: [HTTPCookie]) -> String {
    let dateFormatter = ISO8601DateFormatter.init()
    var cookiesStrings = [String]()
    for cookie in cookies {
        var cookieString = [String]()
        cookieString.append("\(cookie.name)=\(cookie.value)")
        cookieString.append("domain=\(cookie.domain)")
        cookieString.append("path=\(cookie.path)")
        if let expires = cookie.expiresDate {
            cookieString.append("expires=\(dateFormatter.string(from: expires))")
        }
        if cookie.isSecure {
            cookieString.append("secure")
        }
        if cookie.isHTTPOnly {
            cookieString.append("httponly")
        }
        if let sameSite = cookie.sameSitePolicy {
            cookieString.append("SameSite=\(sameSite.rawValue)")
        }
        cookiesStrings.append(cookieString.joined(separator: "; "))
    }
    return cookiesStrings.joined(separator: ", ")
}


func storeCookies(_ cookies: [HTTPCookie] ) {
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false) {

        let attributes = [kSecClass: kSecClassGenericPassword,
                    kSecAttrService: kService,
      kSecUseDataProtectionKeychain: false,
                      kSecValueData: data] as [String: Any]
        _ = SecItemDelete(attributes as CFDictionary)
        let _ = SecItemAdd(attributes as CFDictionary, nil)
    }
}


@discardableResult func getCookies() -> [HTTPCookie]? {
    let attributes = [kSecClass: kSecClassGenericPassword,
                kSecAttrService: kService,
           kSecReturnAttributes: true,
  kSecUseDataProtectionKeychain: false,
                 kSecReturnData: true] as [String: Any]
    var item: CFTypeRef?
    if  SecItemCopyMatching(attributes as CFDictionary, &item) == 0 {
            if let result = item as? [String:AnyObject],
               let cookiesRaw = result["v_Data"] as? Data,
               let cookies = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(cookiesRaw) as? [HTTPCookie] {
                if cookies.count == 0 {
                    return nil
                } else {
                    return cookies
                }
            }
    }
    return nil
}

