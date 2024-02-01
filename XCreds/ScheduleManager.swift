//
//  ScheduleManager.swift
//  XCreds
//
//  Created by Timothy Perfitt on 6/3/22.
//

import Cocoa

class ScheduleManager:TokenManagerFeedbackDelegate, NoMADUserSessionDelegate {

    func credentialsUpdated(_ credentials: Creds) {
        feedbackDelegate?.credentialsUpdated(credentials)
    }


    func tokenError(_ err: String) {
        TCSLogErrorWithMark("authFailure: \(err)")
        feedbackDelegate?.credentialsCheckFailed()
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
    var nextCheckTime = Date()
    var timer:Timer?
    var kerberosPassword:String?
//    var feedbackDelegate:TokenManagerFeedbackDelegate?
    func setNextCheckTime() {
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
        nextCheckTime = Date(timeIntervalSinceNow: (rate*60+minutesRate)*60)

    }
    func checkADPasswordExpire(password:String) {
        TCSLogWithMark()
        let domainName = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aDDomain.rawValue)

        guard let user = try? PasswordUtils.getLocalRecord(getConsoleUser()),
                let kerbPrincArray = user.value(forKey: "dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal") as? Array <String>,
              let kerbPrinc = kerbPrincArray.first else
        {
            return
        }

        if let domainName = domainName, let shortName = kerbPrinc.components(separatedBy: "@").first, domainName.isEmpty==false, shortName.isEmpty==false{
            session = NoMADSession.init(domain: domainName, user: shortName)
            TCSLogWithMark("NoMAD Login User: \(shortName), Domain: \(domainName)")
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

        if let timer = timer, timer.isValid==true {
            return
        }

        nextCheckTime=Date()
        timer=Timer.scheduledTimer(withTimeInterval: 60*5, repeats: true, block: { timer in //check every 5 minutes
            self.checkToken()
        })
        self.checkToken()
    }
    func stopCredentialCheck()  {
        if let timer = timer, timer.isValid==true {
            timer.invalidate()

        }
    }

    func checkToken()  {
        TCSLogWithMark("checking token")
        if nextCheckTime>Date() {
            TCSLogWithMark("Token will be checked at \(nextCheckTime)")

            NotificationCenter.default.post(name: NSNotification.Name("CheckTokenStatus"), object: self, userInfo:["NextCheckTime":nextCheckTime])
            return
        }
        setNextCheckTime()
        let domainName = DefaultsOverride.standardOverride.string(forKey: PrefKeys.aDDomain.rawValue)


        if let _ = domainName, let kerberosPassword = kerberosPassword {
            TCSLogWithMark("checking for kerberos ticket")
            checkADPasswordExpire(password: kerberosPassword)
            return
        }
        else {
            TCSLogWithMark("not checking for kerberos ticket")

        }

        TCSLogWithMark("checking for oidc tokens if configured")
        tokenManager.feedbackDelegate=self

        if  let _ = DefaultsOverride.standardOverride.string(forKey: PrefKeys.discoveryURL.rawValue) {
            
            tokenManager.getNewAccessToken()
        }


    }

    func NoMADAuthenticationSucceded() {
        TCSLogWithMark()
        feedbackDelegate?.kerberosTicketUpdated()
        session?.userInfo()

    }

    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        TCSLogErrorWithMark("NoMADAuthenticationFailed:\(description)")
        feedbackDelegate?.kerberosTicketCheckFailed()
    }

    func NoMADUserInformation(user: ADUserRecord) {
        TCSLogWithMark("AD user password expires: \(user.passwordExpire?.description ?? "unknown")")


        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        if let passExpired = user.passwordExpire {
            let dateString = dateFormatter.string(from: passExpired)
            feedbackDelegate?.passwordExpiryUpdate(dateString)
            feedbackDelegate?.adUserUpdated(user)
//            passwordExpires=dateString

        }
    }


}
