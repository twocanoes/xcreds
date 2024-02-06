//
//  TokenManager.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//
import Foundation
import OIDCLite

struct IDToken:Codable {
    let iss,sub,aud:String
    let iat, exp:Int
    let email:String?
    let unique_name, given_name,family_name,name:String?

    enum CodingKeys: String, CodingKey {
        case iss,sub,aud,name,given_name,family_name,email,iat,exp, unique_name

    }
}

protocol TokenManagerFeedbackDelegate {
    func tokenError(_ err:String)
    func credentialsUpdated(_ credentials:Creds)

}
class TokenManager: OIDCLiteDelegate,DSQueryable {
    struct UserAccountInfo {
        var fullName:String?
        var firstName:String?
        var lastName:String?
        var username:String?
        var groups:Array<String>?
        var alias:String?
        var kerberosPrincipalName:String?
    }
    enum ParseHintsResult:Error {
        case error(String)
    }
    enum ProcessTokenResult:Error {
        case success
        case error(String)
    }
    enum CalculateUserAccountInfoResult {
        case success(UserAccountInfo)
        case error(String)
    }

    var feedbackDelegate:TokenManagerFeedbackDelegate?
    let defaults = DefaultsOverride.standard
    private var oidcLocal:OIDCLite?
    func oidc() -> OIDCLite {
        var scopes: [String]?
        var additionalParameters:[String:String]? = nil

        if let oidcPrivate = oidcLocal {
            oidcPrivate.getEndpoints()

            return oidcPrivate
        }
        let clientSecret = DefaultsOverride.standardOverride.string(forKey: PrefKeys.clientSecret.rawValue)


        
        let clientID = DefaultsOverride.standardOverride.string(forKey: PrefKeys.clientID.rawValue)


        
        if let scopesRaw = DefaultsOverride.standardOverride.string(forKey: PrefKeys.scopes.rawValue) {
            scopes = scopesRaw.components(separatedBy: " ")
        }

        //
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldSetGoogleAccessTypeToOffline.rawValue) == true {

            additionalParameters = ["access_type":"offline"]
        }
        
        let oidcLite = OIDCLite(discoveryURL: DefaultsOverride.standardOverride.string(forKey: PrefKeys.discoveryURL.rawValue) ?? "NONE", clientID: clientID ?? "NONE", clientSecret: clientSecret, redirectURI: DefaultsOverride.standardOverride.string(forKey: PrefKeys.redirectURI.rawValue), scopes: scopes, additionalParameters:additionalParameters )
        oidcLite.getEndpoints()
        oidcLocal = oidcLite
        oidcLite.delegate=self
        return oidcLite


    }

    static func saveTokensToKeychain(creds:Creds, setACL:Bool=false, password:String?=nil) -> Bool {
        let keychainUtil = KeychainUtil()

        if let accessToken = creds.accessToken, accessToken.count>0{
            TCSLogWithMark("Saving Access Token")
            if  keychainUtil.updatePassword(serviceName: "xcreds ".appending(PrefKeys.accessToken.rawValue),accountName:PrefKeys.accessToken.rawValue, pass: accessToken,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating Access Token")

                return false
            }

        }
        if let idToken = creds.idToken, idToken.count>0{
            TCSLogWithMark("Saving idToken Token")
            if  keychainUtil.updatePassword(serviceName: "xcreds ".appending(PrefKeys.idToken.rawValue),accountName:PrefKeys.idToken.rawValue, pass: idToken, shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating idToken Token")

                return false
            }
        }


        if let refreshToken = creds.refreshToken, refreshToken.count>0 {
            TCSLogWithMark("Saving refresh Token")

            if keychainUtil.updatePassword(serviceName: "xcreds ".appending(PrefKeys.refreshToken.rawValue),accountName:PrefKeys.refreshToken.rawValue, pass: refreshToken,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating refreshToken Token")

                return false
            }
        }



        if let password = password, password.count>0 {
            TCSLogWithMark("Saving cloud password")

            if keychainUtil.updatePassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue, pass: password,shouldUpdateACL: setACL, keychainPassword:password) == false {
                TCSLogErrorWithMark("Error Updating password")

                return false
            }

        }
        return true
    }



    func tokenEndpoint() -> String? {

        let prefTokenEndpoint = DefaultsOverride.standardOverride.string(forKey: PrefKeys.tokenEndpoint.rawValue)
        if  prefTokenEndpoint != nil {
            return prefTokenEndpoint
        }


        if let tokenEndpoint = oidc().OIDCTokenEndpoint {
            return tokenEndpoint
        }
        return nil
    }

    func getNewAccessToken() -> Void {
        TCSLogWithMark()

        let keychainUtil = KeychainUtil()
        TCSLogWithMark()
        let refreshAccountAndToken = try? keychainUtil.findPassword(serviceName: "xcreds ".appending(PrefKeys.refreshToken.rawValue),accountName:PrefKeys.refreshToken.rawValue)

        let clientID = defaults.string(forKey: PrefKeys.clientID.rawValue)
        let keychainAccountAndPassword = try? keychainUtil.findPassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue)

        TCSLogWithMark()
        //ropg
        if
            let keychainAccountAndPassword = keychainAccountAndPassword,
            DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseROPGForPasswordChangeChecking.rawValue) == true,

                let keychainPassword = keychainAccountAndPassword.1{
            TCSLogWithMark("Checking credentials in keychain using ROPG")
            let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
            guard let userNames = try? currentUser?.values(forAttribute: "dsAttrTypeNative:_xcreds_oidc_username") as? [String], userNames.count>0, let username = userNames.first else {
                feedbackDelegate?.tokenError("no username for oidc config")
                return
            }
            // not return because we get a callback and then call the closure
            oidc().requestTokenWithROPG(username: username, password: keychainPassword)

        } //use the refresh token
        else if let refreshAccountAndToken = refreshAccountAndToken, let refreshToken = refreshAccountAndToken.1 {

            oidc().refreshTokens(refreshToken)
        } // nothing. let delegate know
        else if DefaultsOverride.standardOverride.value(forKey: PrefKeys.discoveryURL.rawValue) == nil {

            TCSLogWithMark("no discovery URL defined. returning silently.")
            }
        else {
            TCSLogWithMark("clientID or refreshToken blank. clientid: \(clientID ?? "empty") refreshtoken:\(refreshAccountAndToken?.1 ?? "empty")")
            feedbackDelegate?.tokenError("no refresh token")

        }
    }
    func tokenInfo(fromCredentials credentials:Creds) throws -> Dictionary<String, Any>? {
        //if we have tokens, that means that authentication was successful.


        guard let idToken = credentials.idToken else {
            TCSLogErrorWithMark("invalid idToken")
            throw ProcessTokenResult.error("invalid idToken")
        }

        let array = idToken.components(separatedBy: ".")

        if array.count != 3 {
            TCSLogErrorWithMark("idToken is invalid")
            throw ProcessTokenResult.error("The identity token is incorrect length.")
            //            mechanismDelegate.denyLogin(message:"The identity token is incorrect length.")
        }
        let body = array[1]
        TCSLogWithMark("base64 encoded IDToken: \(body)");
        guard let data = base64UrlDecode(value:body ) else {
            TCSLogErrorWithMark("error decoding id token base64")
            throw ProcessTokenResult.error("The identity token could not be decoded from base64.")

            //            mechanismDelegate.denyLogin(message:"The identity token could not be decoded from base64.")
            //            return
        }
        if let decodedTokenString = String(data: data, encoding: .utf8) {
            TCSLogWithMark("IDToken:\(decodedTokenString)")

        }
        let decoder = JSONDecoder()
        var idTokenObject:IDToken
        do {
            idTokenObject = try decoder.decode(IDToken.self, from: data)

        }
        catch {
            TCSLogErrorWithMark("error decoding idtoken::")
            TCSLogErrorWithMark("Token:\(body)")
            throw ProcessTokenResult.error("The identity token could not be decoded from json")
//
//            //            mechanismDelegate.denyLogin(message:"The identity token could not be decoded from json.")
//            //            return
//
        }

        let idTokenInfo = jwtDecode(value: idToken)  //dictionary for mapping
        guard var idTokenInfo = idTokenInfo else {
            throw ProcessTokenResult.error("No idTokenInfo found")

            //            mechanismDelegate.denyLogin(message:"No idTokenInfo found.")
            //            return
        }

        idTokenInfo["idToken"]=idTokenObject
        return idTokenInfo
    }
    func findUserAndUpdatePassword(idTokenInfo:Dictionary<String, Any>,newPassword:String) -> SelectLocalAccountWindowController.VerifyLocalCredentialsResult?{

        TCSLogWithMark()
        guard let subValue = idTokenInfo["sub"] as? String, let issuerValue = idTokenInfo["iss"] as? String else {
            return nil
        }

        TCSLogWithMark("getting users")
        let standardUsers = try? getAllStandardUsers()
        let existingUser = try? getUserRecord(sub: subValue, iss: issuerValue)
        let shouldPromptForMigration = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldPromptForMigration.rawValue)

        if shouldPromptForMigration == false {
            TCSLogWithMark("not prompting for migration")

        }
        if  let existingUser = existingUser, let odUsername = existingUser.recordName  {
            TCSLogWithMark("prior local user found. using.")

            return .successful(odUsername)
        }
        else if let standardUsers = standardUsers, standardUsers.count>0, shouldPromptForMigration == true {

            TCSLogWithMark("Preference set to prompt for migration and there are standard users, so prompting")


            return SelectLocalAccountWindowController.selectLocalAccountAndUpdate(newPassword: newPassword)
        }
        return .createNewAccount
    }
    func setupUserAccountInfo(idTokenInfo:Dictionary<String, Any>)  -> CalculateUserAccountInfoResult {

        TCSLogWithMark()
        var userAccountInfo = UserAccountInfo()
        guard let idTokenObject = idTokenInfo["idToken"] as? IDToken else {
            return .error("invalid token object")

        }
        let defaultsUsername = DefaultsOverride.standardOverride.string(forKey: PrefKeys.username.rawValue)

        // username static map
        if let defaultsUsername = defaultsUsername {
            userAccountInfo.username = defaultsUsername
        }
        else if let mapKey = DefaultsOverride.standardOverride.object(forKey: PrefKeys.mapUserName.rawValue)  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String, let leftSide = mapValue.components(separatedBy: "@").first{

            TCSLogWithMark()
            userAccountInfo.username = leftSide.replacingOccurrences(of: " ", with: "_").stripped
            TCSLogWithMark("mapped username found: \(mapValue) clean version:\(userAccountInfo.username ?? "nil")")
        }
        else {
            TCSLogWithMark()
            var emailString:String

            if let email = idTokenObject.email  {
                emailString=email.lowercased()
            }
            else if let uniqueName=idTokenObject.unique_name {
                emailString=uniqueName
            }

            else {
                TCSLogWithMark("no username found. Using sub.")
                emailString=idTokenObject.sub
            }
            guard let tUsername = emailString.components(separatedBy: "@").first?.lowercased() else {
                TCSLogErrorWithMark("email address invalid")

                return .error("The email address from the identity token is invalid")

            }

            TCSLogWithMark("username found: \(tUsername)")
            userAccountInfo.username = tUsername
        }

        //kerberos principal name

        //mapKerberosPrincipalName

        if let mapKey = DefaultsOverride.standardOverride.object(forKey: PrefKeys.mapKerberosPrincipalName.rawValue)  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
            //we have a mapping so use that.
            TCSLogWithMark("mapKerberosPrincipalName name mapped to: \(mapKey)")
            userAccountInfo.kerberosPrincipalName = mapValue
        }

        //full name
        TCSLogWithMark("checking map_fullname")

        if let mapKey = DefaultsOverride.standardOverride.object(forKey: PrefKeys.mapFullName.rawValue)  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
            //we have a mapping so use that.
            TCSLogWithMark("full name mapped to: \(mapKey)")
            userAccountInfo.fullName = mapValue

        }

        else if let firstName = idTokenObject.given_name, let lastName = idTokenObject.family_name {
            TCSLogWithMark("firstName: \(firstName)")
            TCSLogWithMark("lastName: \(lastName)")
            userAccountInfo.fullName = "\(firstName) \(lastName)"

        }


        //first name
        if let mapKey = DefaultsOverride.standardOverride.object(forKey: PrefKeys.mapFirstName.rawValue)  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
            //we have a mapping for username, so use that.
            TCSLogWithMark("first name mapped to: \(mapKey)")
            userAccountInfo.firstName = mapValue
        }

        else if let given_name = idTokenObject.given_name {
            TCSLogWithMark("firstName from token: \(given_name)")
            userAccountInfo.firstName = given_name

        }
        //last name
        TCSLogWithMark("checking map_lastname")

        if let mapKey = DefaultsOverride.standardOverride.object(forKey: PrefKeys.mapLastName.rawValue)  as? String, mapKey.count>0, let mapValue = idTokenInfo[mapKey] as? String {
            //we have a mapping for lastName, so use that.
            TCSLogWithMark("last name mapped to: \(mapKey)")
            userAccountInfo.lastName = mapValue
        }

        else if let familyName = idTokenObject.family_name {
            TCSLogWithMark("lastName from token: \(familyName)")
            userAccountInfo.lastName = familyName

        }
        //groups
        if let mapValue = idTokenInfo["groups"] as? Array<String> {
            TCSLogWithMark("setting groups: \(mapValue)")
            userAccountInfo.groups = mapValue
        }
        else {

            TCSLogWithMark("No groups found")
        }

        let aliasClaim = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aliasName.rawValue)
        if let aliasClaim = aliasClaim, let aliasClaimValue = idTokenInfo[aliasClaim] as? String {
            TCSLogWithMark("found alias claim: \(aliasClaim):\(aliasClaimValue)")

            userAccountInfo.alias = aliasClaimValue
        }
        else {
            TCSLogWithMark("no alias claim: \(aliasClaim ?? "none")")
        }


        return .success(userAccountInfo)

    }

}
// MARK: OIDC Lite Delegate Functions

extension TokenManager {
    func authFailure(message: String) {
        TCSLogWithMark("authFailure: \(message)")
        feedbackDelegate?.tokenError(message)
    }


    func tokenResponse(tokens: OIDCLite.TokenResponse) {

        TCSLogWithMark("======== tokenResponse =========")

        RunLoop.main.perform {

            let xcredCreds = Creds(password: nil, tokens: tokens)
            if xcredCreds.hasAccessAndRefresh(){
                self.feedbackDelegate?.credentialsUpdated(xcredCreds)
            }
            else {
                self.feedbackDelegate?.tokenError("error gettings tokens")
            }

        }
    }
}

