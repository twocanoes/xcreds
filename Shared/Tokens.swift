//
//  Tokens.swift
//  XCreds
//
//  Created by Timothy Perfitt on 7/2/22.
//

import Foundation
import OIDCLite
struct Creds {
    var password:String? = ""
    public var accessToken: String?
    public var idToken: String?
    public var refreshToken: String?
    public var jsonDict: [String:Any]?

    init(password:String?, tokens:OIDCLite.TokenResponse) {

        self.accessToken=tokens.accessToken
        self.idToken=tokens.idToken
        self.refreshToken=tokens.refreshToken
        self.password=password
        self.jsonDict=tokens.jsonDict

   }
    init(accessToken:String?, idToken:String?,refreshToken:String?, password:String?,jsonDict:Dictionary <String,Any>,pass:String) {

        self.accessToken=accessToken
        self.idToken=idToken
        self.refreshToken=refreshToken
        self.password=pass
        self.jsonDict=jsonDict

   }

    
}



