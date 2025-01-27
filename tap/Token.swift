//
//  Token.swift
//
//  Created by Timothy Perfitt on 6/18/24.
//

import CryptoTokenKit

class Token: TKSmartCardToken, TKTokenDelegate {

    init(smartCard: TKSmartCard, aid AID: Data?, tokenDriver: TKSmartCardTokenDriver) throws {
        
        let instanceID = "xcredstap" // Fill in a unique persistent identifier of the token instance.
        super.init(smartCard: smartCard, aid:nil, instanceID:instanceID, tokenDriver: tokenDriver)
    }

    func createSession(_ token: TKToken) throws -> TKTokenSession {
        return TokenSession(token:self)
    }

}
