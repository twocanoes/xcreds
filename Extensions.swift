//
//  Extensions.swift
//  NoMAD
//
//  Created by Boushy, Phillip on 10/4/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

import Foundation

// bitwise convenience
prefix operator ~~

prefix func ~~(value: Int) -> Bool {
    return (value > 0) ? true : false
}

extension UserDefaults {
    func sint(forKey defaultName: String) -> Int? {
        
        let defaults = UserDefaults.standard
        let item = defaults.object(forKey: defaultName)
        
        if item == nil {
            return nil
        }
        
        // test to see if it's an Int
        
        if let result = item as? Int {
            return result
        } else {
            // it's a String!
            
            return Int(item as! String)
        }
    }
}

extension String {
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func containsIgnoringCase(_ find: String) -> Bool {
        return self.range(of: find, options: NSString.CompareOptions.caseInsensitive) != nil
    }
    
    /*
     
     // TODO: move this to UserInfo
    
    func variableSwap() -> String {
        
        var cleanString = self
        
        let domain = defaults.string(forKey: Preferences.aDDomain) ?? ""
        let fullName = defaults.string(forKey: Preferences.displayName)?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        let serial = getSerial().addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        let shortName = defaults.string(forKey: Preferences.userShortName) ?? ""
        let upn = defaults.string(forKey: Preferences.userUPN) ?? ""
        let email = defaults.string(forKey: Preferences.userEmail) ?? ""
        
        cleanString = cleanString.replacingOccurrences(of: "<<domain>>", with: domain)
        cleanString = cleanString.replacingOccurrences(of: "<<fullname>>", with: fullName)
        cleanString = cleanString.replacingOccurrences(of: "<<serial>>", with: serial)
        cleanString = cleanString.replacingOccurrences(of: "<<shortname>>", with: shortName)
        cleanString = cleanString.replacingOccurrences(of: "<<upn>>", with: upn)
        cleanString = cleanString.replacingOccurrences(of: "<<email>>", with: email)
        
        return cleanString //.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        
    }
 */
    
}
