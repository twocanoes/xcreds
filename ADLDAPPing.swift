//
//  ADLDAPPing.swift
//  NoMAD
//
//  Created by Michael Lynn, Phillip Boushy on 10/8/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

import Foundation

struct DS_FLAGS : OptionSet {
    let rawValue: UInt32
    init(rawValue value: UInt32) {
        rawValue = value
    }
    // List of DS_FLAGS variables
    // https://msdn.microsoft.com/en-us/library/cc223802.aspx
    static let DS_PDC_FLAG = DS_FLAGS(rawValue: 1 << 0)
    // 1 is reserved for future expansion
    static let DS_GC_FLAG = DS_FLAGS(rawValue: 1 << 2)
    static let DS_LDAP_FLAG = DS_FLAGS(rawValue: 1 << 3)
    static let DS_DS_FLAG = DS_FLAGS(rawValue: 1 << 4) //
    static let DS_KDC_FLAG = DS_FLAGS(rawValue: 1 << 5)
    static let DS_TIMESERV_FLAG = DS_FLAGS(rawValue: 1 << 6)
    static let DS_CLOSEST_FLAG = DS_FLAGS(rawValue: 1 << 7)
    static let DS_WRITABLE_FLAG = DS_FLAGS(rawValue: 1 << 8)
    static let DS_GOOD_TIMESERV_FLAG = DS_FLAGS(rawValue: 1 << 9)
    static let DS_NDNC_FLAG = DS_FLAGS(rawValue: 1 << 10)
    static let DS_SELECT_SECRET_DOMAIN_6_FLAG = DS_FLAGS(rawValue: 1 << 11)
    static let DS_FULL_SECRET_DOMAIN_6_FLAG = DS_FLAGS(rawValue: 1 << 12)
    static let DS_WS_FLAG = DS_FLAGS(rawValue: 1 << 13)
    static let DS_DS_8_FLAG = DS_FLAGS(rawValue: 1 << 14)
    static let DS_DS_9_FLAG = DS_FLAGS(rawValue: 1 << 15)
    // 16 - 28 are reserved for future expansion
    static let DS_DNS_CONTROLLER_FLAG = DS_FLAGS(rawValue: 1 << 29)
    static let DS_DNS_DOMAIN_FLAG = DS_FLAGS(rawValue: 1 << 30)
    static let DS_DNS_FOREST_FLAG = DS_FLAGS(rawValue: 1 << 31)
}

class ADLDAPPing {
    //var currentDataLocation: Int
    var type: UInt32 //uint32
    var flags: DS_FLAGS //uint32
    var domainGUID: UUID
    var forest: String //rfc1035
    var domain: String //rfc1035
    var hostname: String //rfc1035
    var netbiosDomain: String //rfc1035
    var netbiosHostname: String //rfc1035
    var user: String //rfc1035
    var clientSite: String //rfc1035
    var serverSite: String

    class func decodeGUID(_ buffer: Data, start: Int) -> UUID {
        var bytes: [UInt8] = [UInt8](repeating: 0, count: 16)
        let length: Int = 16
        (buffer as NSData).getBytes(&bytes, range: NSRange(location: start, length: length))
        return (NSUUID(uuidBytes: bytes) as UUID)
    }

    class func decodeUInt32(_ buffer: Data, start: Int) -> UInt32 {
        var value: UInt32 = 0
        let length: Int = 4
        (buffer as NSData).getBytes(&value, range: NSRange(location: start, length: length))
        return value
    }

    enum DecodeError: Error {
        case illegalTag
        case cyclicPointer
    }

    class func decodeRFC1035(_ buffer: Data, start: UInt16, seen: Set<UInt16>?) throws -> (r: String, c: UInt16) {
        let marker: UInt8 = 0xc0
        var cursor: UInt16 = start
        var result: [String] = []
        var pointers: Set<UInt16>
        pointers = Set<UInt16>()
        if (seen != nil) {
            pointers.formUnion(seen!)
        }
        while true {
            var tag: UInt8 = 0
            (buffer as NSData).getBytes(&tag, range: NSRange(location: Int(cursor), length: 1))
            cursor += 1
            if (tag == 0) {
                // end of a sequence, time to tally up and return results
                break
            } else if ((tag & marker) == marker) {
                var byte: UInt8 = 0
                (buffer as NSData).getBytes(&byte, range: NSRange(location: Int(cursor), length: 1))
                cursor += 1
                // we would appear to have a pointer, let's remember it
                var ptr: UInt16 = 0
                let d: [UInt8]  = [byte, (tag & ~marker)]
                //				ptr += UnsafePointer<UInt16>(d).pointee
                ptr += UnsafePointer(d).withMemoryRebound(to: UInt16.self,
                                                          capacity: 1) {
                                                            $0.pointee
                }
                // check if we've seen it before already
                if pointers.contains(ptr) {
                    throw DecodeError.cyclicPointer
                }
                pointers.insert(ptr)
                let (sresult, _) = try ADLDAPPing.decodeRFC1035(buffer, start: ptr, seen: pointers)
                result.append(sresult)
                break
            } else if ((tag & marker) > 0) {
                throw DecodeError.illegalTag
            } else {
                // read 'tag'-many bytes
                var s: [UInt8] = [UInt8](repeating: 0, count: Int(tag))
                (buffer as NSData).getBytes(&s, range: NSRange(location: Int(cursor), length: Int(tag)))
                cursor += UInt16(tag)
                result.append(NSString(bytes: s, length: Int(tag), encoding: String.Encoding.utf8.rawValue)! as String)
            }
        }
        let final = result.joined(separator: ".")
        return (final, cursor)
    }

    init?( ldapPingBase64String: String ) {
        //let cleanedNetlogonBase64String = netlogonBase64String.componentsSeparatedByString(": ")[1]
        guard let netlogonData = Data(base64Encoded: ldapPingBase64String, options: []) else {
            myLogger.logit(.notice, message: "Netlogon base64 encoded string is invalid.")
            return nil
        }
        var cursor = UInt16(24)

        type = ADLDAPPing.decodeUInt32(netlogonData, start: 0)
        let tempFlags = ADLDAPPing.decodeUInt32(netlogonData, start: 4)
        //flags = ADLDAPPing.decodeUInt32(netlogonData, start: 4)

        // Decode Flags
        flags = DS_FLAGS(rawValue: tempFlags)
        //flags.contains(.DS_PDC_FLAG)

        myLogger.logit(.debug, message: "Is PDC: " + flags.contains(.DS_PDC_FLAG).description)
        myLogger.logit(.debug, message: "Is GC: " + flags.contains(.DS_GC_FLAG).description)
        myLogger.logit(.debug, message: "Is LDAP: " + flags.contains(.DS_LDAP_FLAG).description)
        myLogger.logit(.debug, message: "Is Writable: " + flags.contains(.DS_WRITABLE_FLAG).description)
        myLogger.logit(.debug, message: "Is Closest: " + flags.contains(.DS_CLOSEST_FLAG).description)


        // END

        domainGUID = ADLDAPPing.decodeGUID(netlogonData, start: 8)
        // Get forest
        do {
            (forest, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
        // Get domain
        do {
            (domain, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
        // Get hostname
        do {
            (hostname, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
        // Get netbiosDomain
        do {
            (netbiosDomain, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
        // Get netbiosHostname
        do {
            (netbiosHostname, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
        // Get user
        do {
            (user, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
        // Get the site the DC is in.
        do {
            (serverSite, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
        // Get the site the client is in.
        do {
            (clientSite, cursor) = try ADLDAPPing.decodeRFC1035(netlogonData, start: cursor, seen:nil)
        } catch let error {
            switch error {
            case DecodeError.cyclicPointer:
                myLogger.logit(.notice, message: "Decoding RFC1035 string created loop.")
            case DecodeError.illegalTag:
                myLogger.logit(.notice, message: "Decoding RFC1035 string found an illegal tag.")
            default:
                myLogger.logit(.notice, message: "Unable to decode RFC1035 string.")
            }
            return nil
        }
    }
    
}
