//
//  SessionManager.swift
//  NoMAD-ADAuth
//
//  Created by Joel Rennich on 11/10/17.
//  Copyright © 2018 Orchard & Grove Inc. All rights reserved.
//

import Foundation
//import NoMADPRIVATE

// what we're keeping track of for every user
@available(macOS, deprecated: 11)
public struct NoMADSessionUserObject {
    var userPrincipal: String
    var session: NoMADSession
    var aging: Bool
    var expiration: Date?
    var daysToGo: Int?
    var userInfo: ADUserRecord?
}

// class to keep track and manage multiple AD sessions simultaneously
@available(macOS, deprecated: 11)
public class SessionManager: NoMADUserSessionDelegate {

    /// The default instance of `SessionManager` to be used.
    public static let shared = SessionManager()

    public var sessions = [String : NoMADSessionUserObject]()

    let dateFormatter = DateFormatter()
    let myWorkQueue = DispatchQueue(label: "menu.nomad.NoMADADAuth.sessionmanager.background_work_queue", attributes: [])
    
    init() {
        
        // a bit more setup
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        // get all of the current principals with tickets
        self.getList()
    }
    
    // udpate the list
    
    public func update(user : String) {
        
        if sessions[user] == nil {
            
            // We don't know about this user yet
            return
        }
        
        sessions[user]?.session.delegate = self
        let _ = sessions[user]?.session.getUserInformation()

    }
    
    // updates all known users
    
    public func updateAll() {
        
        if sessions.count < 1 {
            // no sessions so return
            return
        }
        
        for session in sessions {
            session.value.session.delegate = self
            let _ = session.value.session.getUserInformation()
        }
        
    }
    
    // gets new list of users
    
    public func getList() {
        
        klistUtil.klist()
        let principals = klistUtil.returnPrincipals()
        
        if principals.count > 0 {
            for user in principals {
                if sessions[user] == nil {
                    // add the account
                    
                    let userSession = NoMADSession.init(domain: user.components(separatedBy: "@").last?.lowercased() ?? "", user: user, type: .AD)
                    
                    myWorkQueue.async {
                        userSession.delegate = self
                        userSession.userInfo()
                        
                    }
                    sessions[user] = NoMADSessionUserObject.init(userPrincipal: user, session: userSession, aging: false, expiration: nil, daysToGo: nil, userInfo: nil)
                }
            }
        }
        
    }
    
    // manually adds a user with a session
    
    public func createEntry(user : String, session : NoMADSession, update: Bool=true) {
        
        sessions[user] = NoMADSessionUserObject.init(userPrincipal: user, session: session, aging: false, expiration: nil, daysToGo: nil, userInfo: nil)
        
        if update {
            // update the information

            session.delegate = self
            let _ = session.getUserInformation()
        }
        
    }
    
    // update a NoMADSessionUserObject object
    
    public func updateUser(user : String) {
        
    }
    
    // Add a new session to the list
    
    // PRAGMA: Auth callbacks
    
    public func NoMADAuthenticationSucceeded() {
        // we'll never auth here
    }
    
    public func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        // we'll never auth here
    }
    
    public func NoMADUserInformation(user: ADUserRecord) {
        
        // we shouldn't not already know about this user, but we'll double check
        
        if sessions[user.userPrincipal] == nil {
            return
        }
        
        if user.passwordExpire != nil && user.passwordAging! {
            sessions[user.userPrincipal]?.daysToGo = Int((user.passwordExpire?.timeIntervalSince(Date()))!)/86400
            sessions[user.userPrincipal]?.expiration = user.passwordExpire
            sessions[user.userPrincipal]?.aging = true
        } else {
            sessions[user.userPrincipal]?.aging = false
        }
    }
}
