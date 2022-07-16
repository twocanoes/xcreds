//
//  Helper+URLDecode.swift
//  XCreds
//
//  Created by Timothy Perfitt on 7/13/22.
//

import Foundation

func base64UrlDecode(value: String) -> Data? {
    var base64 = value.replacingOccurrences(of: "-", with: "+")
                 .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLenght = 4 * ceil(length/4)
    let paddingLenght = requiredLenght - length
    if paddingLenght > 0 {
        let padding = "".padding(toLength: Int(paddingLenght), withPad: "=", startingAt: 0)
        base64 += padding
    }

    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}
