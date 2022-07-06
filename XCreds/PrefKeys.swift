//
//  PrefKeys.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Foundation

enum PrefKeys: String {
    case clientID, clientSecret, password="local password",discoveryURL, redirectURI, scopes, accessToken, idToken, refreshToken, tokenEndpoint, expirationDate, invalidToken, refreshRateHours, showDebug, verifyPassword, shouldShowQuitMenu, shouldShowPreferencesOnStart, shouldSetGoogleAccessTypeToOffline, passwordChangeURL, shouldShowAboutMenu
}
