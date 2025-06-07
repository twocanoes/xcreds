//
//  ScheduleManager.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa
import OIDCLite

class ScheduleManager:NoMADUserSessionDelegate {

    func invalidCredentials() {
        feedbackDelegate?.invalidCredentials()

    }

    func credentialsUpdated(_ credentials: Creds) {
        feedbackDelegate?.credentialsUpdated(credentials)
    }


    func tokenError(_ err: String) {
        TCSLogErrorWithMark("authFailure: \(err)")
        feedbackDelegate?.credentialsCheckFailed()
        XCredsAudit().auditError(err)
//        //        NotificationCenter.default.post(name: Notification.Name("TCSTokensUpdated"), object: self, userInfo:[:])
//        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.showDebug.rawValue) == true {
//
//            NotifyManager.shared.sendMessage(message: "Password changed or not set")
//        }
//        DispatchQueue.main.async {
//
////            sharedMainMenu.signInMenuItem.showSigninWindow()
//        }

    }

    var session:NoMADSession?

    var feedbackDelegate:UpdateCredentialsFeedbackProtocol?
//    static let shared=ScheduleManager()
    var tokenManager=TokenManager()
    var nextADCheckTime = Date()
    var nextTokenCheckTime = Date()

    var timer:Timer?
    var kerberosPassword:String?

    enum CheckTimer {
        case ADTimer
        case TokenTimer
    }
//    var feedbackDelegate:TokenManagerFeedbackDelegate?
    func setNextCheckTime(timer:CheckTimer) {
        var rate = DefaultsOverride.standardOverride.double(forKey: PrefKeys.refreshRateHours.rawValue)
        var minutesRate = DefaultsOverride.standardOverride.double(forKey: PrefKeys.refreshRateMinutes.rawValue)

        if minutesRate < 0 {
            minutesRate=0
        }

        else if minutesRate > 60 {
            minutesRate=60
        }
        if rate < 0 {
            rate = 0
        }
        else if rate > 168 {
            rate = 168
        }
        if rate == 0 && minutesRate == 0 {

            rate=3
        }
        switch timer {

        case .ADTimer:
            nextADCheckTime = Date(timeIntervalSinceNow: (rate*60+minutesRate)*60)

        case .TokenTimer:
            nextTokenCheckTime = Date(timeIntervalSinceNow: (rate*60+minutesRate)*60)

        }

    }
    func checkADPasswordExpire(password:String) {
        TCSLogWithMark()

        let adDomainFromPrefs = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aDDomain.rawValue)
        var allDomainsFromPrefs = DefaultsOverride.standardOverride.array(forKey: PrefKeys.additionalADDomainList.rawValue)  as? [String] ?? []

        if let adDomainFromPrefs=adDomainFromPrefs  {
            allDomainsFromPrefs.append(adDomainFromPrefs)
        }
        allDomainsFromPrefs = allDomainsFromPrefs.map { currVal in
            currVal.uppercased()
        }

        guard let user = try? PasswordUtils.getLocalRecord(getConsoleUser()),
              let kerbPrincArray = user.value(forKey: "dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal") as? Array <String>,
              var kerbPrinc = kerbPrincArray.first else
        {
            return
        }
        if kerbPrinc.contains("@") == false, let adDomainFromPrefs = adDomainFromPrefs {
            kerbPrinc = kerbPrinc + "@" + adDomainFromPrefs.stripped
        }

        if allDomainsFromPrefs.count>0,
           let shortName = kerbPrinc.components(separatedBy: "@").first,
            let specifiedDomain = kerbPrinc.components(separatedBy: "@").last,
            specifiedDomain.isEmpty==false,
            shortName.isEmpty==false,
           allDomainsFromPrefs.contains(specifiedDomain.uppercased())==true
        {
            session = NoMADSession.init(domain: specifiedDomain, user: shortName)
            TCSLogWithMark("NoMAD Login User: \(shortName), Domain: \(specifiedDomain)")
            guard let session = session else {
                TCSLogErrorWithMark("Could not create NoMADSession from SignIn window")
                return
            }

            session.useSSL = getManagedPreference(key: .LDAPOverSSL) as? Bool ?? false
            session.userPass = password
            session.delegate = self
            session.recursiveGroupLookup = getManagedPreference(key: .RecursiveGroupLookup) as? Bool ?? false

            if let ignoreSites = getManagedPreference(key: .IgnoreSites) as? Bool {

                session.siteIgnore = ignoreSites
            }

            if let ldapServers = getManagedPreference(key: .LDAPServers) as? [String] {
                TCSLogWithMark("Adding custom LDAP servers")

                session.ldapServers = ldapServers
            }

            TCSLogWithMark("Attempt to authenticate user")
            session.authenticate()
        }


    }
    func startCredentialCheck()  {
        TCSLogWithMark()

        //                NotificationCenter.default.post(name: NSNotification.Name("KerberosPasswordChanged"), object: ["updatedPassword":newPassword])


        NotificationCenter.default.addObserver(forName: NSNotification.Name("KerberosPasswordChanged"), object: nil, queue: .main, using: { notification in
            if let newPassword = notification.object as? [String:String],
                let newPassword = newPassword["updatedPassword"] {
                TCSLogWithMark("new kerb password received:")
                self.kerberosPassword=newPassword
            }
        })

        if let timer = timer, timer.isValid==true {
            return
        }

        nextADCheckTime=Date()
        nextTokenCheckTime=Date()

        timer=Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { timer in //check every 30 seconds
            self.checkToken()
        })
        self.checkToken()
    }
    func stopCredentialCheck()  {
        if let timer = timer, timer.isValid==true {
            timer.invalidate()

        }
    }
    func checkKerberosTicket(){
        let domainName = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aDDomain.rawValue)


        if let _ = domainName, let kerberosPassword = kerberosPassword {
            TCSLogWithMark("checking for kerberos ticket")
            checkADPasswordExpire(password: kerberosPassword)
        }
        else {
            TCSLogWithMark("not checking for kerberos ticket")
        }

    }
    func checkToken()  {
        TCSLogWithMark("checking token if needed")
        if nextADCheckTime>Date()  && nextTokenCheckTime > Date() {
            TCSLogWithMark("Not time to check yet. AD Token will be checked at \(nextADCheckTime) and OIDC token will be checked at \(nextTokenCheckTime)")
            return
        }
        if nextADCheckTime<Date(){
            setNextCheckTime(timer:.ADTimer)
            checkKerberosTicket()
        }

        if  nextTokenCheckTime<Date(){
            setNextCheckTime(timer:.TokenTimer)

            TCSLogWithMark("checking for oidc tokens if we have a refresh token and oidc is configured.")

            let keychainUtil = KeychainUtil()

            let refreshAccountAndToken = try? keychainUtil.findPassword(serviceName: "xcreds ".appending(PrefKeys.refreshToken.rawValue),accountName:PrefKeys.refreshToken.rawValue)
            var hasValidRefreshToken = false

            if  let _ = DefaultsOverride.standardOverride.string(forKey: PrefKeys.discoveryURL.rawValue),
                let refreshAccountAndToken = refreshAccountAndToken,
                let refreshToken = refreshAccountAndToken.1,

                    refreshToken != ""  {
                hasValidRefreshToken = true
            }
            if hasValidRefreshToken || DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldUseROPGForPasswordChangeChecking.rawValue) {

                TCSLogWithMark("We have a refresh token or are using ROPG for menu login.")

                //check to make sure we are not in an error state
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate,.withFullTime]


                var isLoginInFailedState = false
                let ud = UserDefaults.standard
                //
                if let _ = ud.string(forKey: PrefKeys.lastOIDCLoginFailTimestamp.rawValue){
                    isLoginInFailedState=true
                    TCSLogWithMark("We have a prior failed login attempt.")
                }
                TCSLogWithMark("Checking to see if the login window was successful after the last failed attempt. If so, we can go ahead and try to authenticate.")

                if let lastOIDCLoginFailTimestampString = ud.string(forKey: PrefKeys.lastOIDCLoginFailTimestamp.rawValue),
                   let lastOIDCLoginFailTimestampDate = try? Date.ISO8601FormatStyle().parseStrategy.parse(lastOIDCLoginFailTimestampString ) {


                        //last login failed. We can proceed only if there was a successful login at the login window.
                        if let user = try? PasswordUtils.getLocalRecord(getConsoleUser()),
                           let oidcLastLoginTimestampStringFromDSArray = user.value(forKey: "dsAttrTypeNative:_xcreds_oidc_lastLoginTimestamp") as? [String],
                           let oidcLastLoginTimestampStringFromDS = oidcLastLoginTimestampStringFromDSArray.first,
                           let oidcLastLoginTimestameDateFromLoginWindow = try? Date.ISO8601FormatStyle().parseStrategy.parse(oidcLastLoginTimestampStringFromDS),
                           oidcLastLoginTimestameDateFromLoginWindow > lastOIDCLoginFailTimestampDate {

                            TCSLogWithMark("Login success at login window so we can go ahead and try to authenticate.")


                            isLoginInFailedState=false

                        }
                    }
                    if isLoginInFailedState==true {
                        TCSLogWithMark("***** Invalid credentials from prior attempts. Prompting user ******")

                        feedbackDelegate?.invalidCredentials()
                        return
                    }

                Task{
                    do{
                        try await tokenManager.oidc().getEndpoints()
                        TCSLogWithMark("requesting new access token")
                        let tokenResponse = try await tokenManager.getNewAccessToken()
                        TCSLogWithMark("success. Setting new token.")
                        ud.removeObject(forKey: PrefKeys.lastOIDCLoginFailTimestamp.rawValue)

                        let creds = try? keychainUtil.findPassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue)
                        if let localPassword = creds?.1 {
                            feedbackDelegate?.credentialsUpdated(Creds(accessToken: tokenResponse?.accessToken, idToken: tokenResponse?.idToken, refreshToken: tokenResponse?.refreshToken, password:localPassword, jsonDict: [:]))
                        }

                    }
                    catch let error  {

                        TCSLogWithMark("Error")
                        switch error {

                        case OIDCLiteError.authFailure(let mesg):
                            TCSLogWithMark("invalid credentials: \(mesg)")
                            TCSLogWithMark("Setting last failed login timestamp to now.")

                            ud.setValue(ISO8601DateFormatter().string(from: Date()), forKey: PrefKeys.lastOIDCLoginFailTimestamp.rawValue)
                            feedbackDelegate?.invalidCredentials()

                        default:
                            TCSLogWithMark("Delaying check for oidc tokens because endpoints are not available yet. Error: \(error)")
                            nextTokenCheckTime=Date.distantPast

                        }
                    }
                }
            }
        }
    }

    func NoMADAuthenticationSucceeded() {
        TCSLogWithMark()
        if let userPrinc = session?.userPrincipal {
            TCTaskHelper.shared().runCommand("/usr/bin/kswitch", withOptions: ["-p", userPrinc])
//            let _ = cliTask("/usr/bin/kswitch -p " +  userPrinc)
        }
        feedbackDelegate?.kerberosTicketUpdated()
        session?.userInfo()



    }

    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        TCSLogErrorWithMark("AuthenticationFailed:\(description)")
        switch error {

        case .OffDomain:
            nextADCheckTime=Date.distantPast
        default:
            break
        }
        feedbackDelegate?.kerberosTicketCheckFailed(error)
    }

    func NoMADUserInformation(user: ADUserRecord) {
        TCSLogWithMark("AD user password expires: \(user.passwordExpire?.description ?? "unknown")")


        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        if let passExpired = user.passwordExpire {
//            let dateString = dateFormatter.string(from: passExpired)
            feedbackDelegate?.passwordExpiryUpdate(passExpired)
            feedbackDelegate?.adUserUpdated(user)

        }
    }


}
