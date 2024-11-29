//
//  TokenSession.swift
//  tapgo
//
//  Created by Timothy Perfitt on 6/18/24.
//

import CryptoTokenKit

class TokenSession: TKSmartCardTokenSession, TKTokenSessionDelegate {

    func tokenSession(_ session: TKTokenSession, beginAuthFor operation: TKTokenOperation, constraint: Any) throws -> TKTokenAuthOperation {
        return TKTokenSmartCardPINAuthOperation()
    }
    
    func tokenSession(_ session: TKTokenSession, supports operation: TKTokenOperation, keyObjectID: Any, algorithm: TKTokenKeyAlgorithm) -> Bool {
        // Indicate whether the given key supports the specified operation and algorithm.
        return true
    }
    
    func tokenSession(_ session: TKTokenSession, sign dataToSign: Data, keyObjectID: Any, algorithm: TKTokenKeyAlgorithm) throws -> Data {
        var signature: Data?
        
        // Insert code here to sign data using the specified key and algorithm.
        signature = nil
        
        if let signature = signature {
            return signature
        } else {
            // If the operation failed for some reason, fill in an appropriate error like objectNotFound, corruptedData, etc.
            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
            throw NSError(domain: TKErrorDomain, code: TKError.Code.authenticationNeeded.rawValue, userInfo: nil)
        }
    }
    
    func tokenSession(_ session: TKTokenSession, decrypt ciphertext: Data, keyObjectID: Any, algorithm: TKTokenKeyAlgorithm) throws -> Data {
        var plaintext: Data?
        // Insert code here to decrypt the ciphertext using the specified key and algorithm.
        plaintext = nil
        
        if let plaintext = plaintext {
            return plaintext
        } else {
            // If the operation failed for some reason, fill in an appropriate error like objectNotFound, corruptedData, etc.
            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
            throw NSError(domain: TKErrorDomain, code: TKError.Code.authenticationNeeded.rawValue, userInfo: nil)
        }
    }
    
    func tokenSession(_ session: TKTokenSession, performKeyExchange otherPartyPublicKeyData: Data, keyObjectID objectID: Any, algorithm: TKTokenKeyAlgorithm, parameters: TKTokenKeyExchangeParameters) throws -> Data {
        var secret: Data?
        
        // Insert code here to perform Diffie-Hellman style key exchange.
        secret = nil
        
        if let secret = secret {
            return secret
        } else {
            // If the operation failed for some reason, fill in an appropriate error like objectNotFound, corruptedData, etc.
            // Note that responding with TKErrorCodeAuthenticationNeeded will trigger user authentication after which the current operation will be re-attempted.
            throw NSError(domain: TKErrorDomain, code: TKError.Code.authenticationNeeded.rawValue, userInfo: nil)
        }
    }
}
