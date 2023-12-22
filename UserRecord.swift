//
//  UserRecord.swift
//  nomad-ad
//
//  Created by Joel Rennich on 9/9/17.
//  Copyright © 2018 Orchard & Grove Inc. All rights reserved.
//

import Foundation

public protocol NoMADUserRecord {
    var firstName: String { get }
    var lastName: String { get }
    var fullName: String { get }
    var shortName: String { get }
    var upn: String { get }
    var email: String? { get }
    var groups: [String] { get }
    var homeDirectory: String? { get }
    var passwordSet: Date { get }
    var passwordExpire: Date? { get }
    var uacFlags: Int? { get }
}

public struct ADUserRecord: NoMADUserRecord, Equatable {
    
    public let type : LDAPType = .AD
    public var userPrincipal : String
    public var firstName: String
    public var lastName: String
    public var fullName: String
    public var shortName: String
    public var upn: String
    public var email: String?
    public var groups: [String]
    public var homeDirectory: String?
    public var passwordSet: Date
    public var passwordExpire: Date?
    public var uacFlags: Int?
    public var passwordAging: Bool?
    public var computedExireDate: Date?
    public var updatedLast: Date
    public var domain: String
    public var cn: String
    public var pso: String?
    public var passwordLength: Int?
    public var ntName: String
    public var customAttributes: [String:Any]?
    
    public static func ==(lhs: ADUserRecord, rhs: ADUserRecord) -> Bool {
        return (lhs.firstName == rhs.firstName && lhs.lastName == rhs.lastName)
    }
}
