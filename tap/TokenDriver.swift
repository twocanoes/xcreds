//
//  TokenDriver.swift
//
//  Created by Timothy Perfitt on 6/18/24.
//

import CryptoTokenKit

class TokenDriver: TKSmartCardTokenDriver, TKSmartCardTokenDriverDelegate {

    func tokenDriver(_ driver: TKSmartCardTokenDriver, createTokenFor smartCard: TKSmartCard, aid AID: Data?) throws -> TKSmartCardToken {
        return try Token(smartCard: smartCard, aid: nil, tokenDriver: self)
    }

}
