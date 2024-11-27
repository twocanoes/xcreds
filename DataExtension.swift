//
//  DataExtension.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 4/10/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation

extension String {
        enum ExtendedEncoding {
            case hexadecimal
        }

        func data(using encoding:ExtendedEncoding) -> Data? {
            var hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)

            if hexStr.count % 2 != 0 {
                hexStr += "0"
            }

            var newData = Data(capacity: hexStr.count/2)

            var indexIsEven = true
            for i in hexStr.indices {
                if indexIsEven {
                    let byteRange = i...hexStr.index(after: i)
                    guard let byte = UInt8(hexStr[byteRange], radix: 16) else {
                        return nil }
                    newData.append(byte)
                }
                indexIsEven.toggle()
            }
            return newData
        }
    }

extension Data {

    init?(fromHexEncodedString string: String) {

        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
        func decodeNibble(u: UInt16) -> UInt8? {
            switch(u) {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }

        self.init(capacity: string.utf16.count/2)
        var even = true
        var byte: UInt8 = 0
        for c in string.utf16 {
            guard let val = decodeNibble(u: c) else { return nil }
            if even {
                byte = val << 4
            } else {
                byte += val
                self.append(byte)
            }
            even = !even
        }
        guard even else { return nil }
    }

    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
