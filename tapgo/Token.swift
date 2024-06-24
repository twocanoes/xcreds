//
//  Token.swift
//  tapgo
//
//  Created by Timothy Perfitt on 6/18/24.
//

import CryptoTokenKit

class Token: TKSmartCardToken, TKTokenDelegate {

    init(smartCard: TKSmartCard, aid AID: Data?, tokenDriver: TKSmartCardTokenDriver) throws {
        
        let instanceID = "xcredstapgo" // Fill in a unique persistent identifier of the token instance.
        super.init(smartCard: smartCard, aid:nil, instanceID:instanceID, tokenDriver: tokenDriver)
        // Insert code here to enumerate token objects and populate keychainContents with instances of TKTokenKeychainCertificate, TKTokenKeychainKey, etc.

//        let items = [TKTokenKeychainItem]()
//        self.keychainContents!.fill(with: items)
    }

    func createSession(_ token: TKToken) throws -> TKTokenSession {
        return TokenSession(token:self)
    }

}
