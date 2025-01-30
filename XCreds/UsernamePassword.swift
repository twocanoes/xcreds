//
//  UsernamePassword.swift
//  XCreds
//
//  Created by Timothy Perfitt on 1/29/25.
//

class LocalAdminCredentials:NSObject, NSSecureCoding{
    required init?(coder: NSCoder) {
        username = coder.decodeObject(forKey: "username") as? String ?? ""
        password = coder.decodeObject(forKey: "password") as? String ?? ""

    }
    public static var supportsSecureCoding: Bool {
        return true
    }

    public func encode(with coder: NSCoder) {
        coder.encode(username, forKey:"username")
        coder.encode(password, forKey:"password")
    }

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    var username:String
    var password:String

    func hasEmptyValues() -> Bool {
        if username.isEmpty || password.isEmpty {
            return true
        }
        return false
    }
}



