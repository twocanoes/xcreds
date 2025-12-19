//
//  main.swift
//  FilevaultLoginHelper
//
//  Created by Timothy Perfitt on 10/3/25.
//

import Foundation
import os.log
 
let log = Logger(subsystem: "com.twocanoes.xcreds", category: "daemon")
@objc(HelperToolProtocol)
public protocol HelperToolProtocol {
    func authFV(username:String, password:String, withReply reply: @escaping (Bool) -> Void)
    func authFVAsAdmin(withReply reply: @escaping (Bool) -> Void)

}


// XPC Communication setup
class HelperToolDelegate: NSObject, NSXPCListenerDelegate, HelperToolProtocol {
    
    func GetSecureTokenUserList() -> [String] {
        let launchPath = "/usr/bin/fdesetup"
        let args = [
            "list"
        ]
        let secureTokenListRaw = cliTask(launchPath, arguments: args, waitForTermination: true)
        let partialList = secureTokenListRaw.components(separatedBy: "\n")
        var secureTokenUsers = [String]()
        for entry in partialList {
            let username = entry.components(separatedBy: ",")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if username != ""{
                secureTokenUsers.append(entry.components(separatedBy: ",")[0])
            }
        }

        return secureTokenUsers
    }

    
    // Accept new XPC connections by setting up the exported interface and object.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Validate that the main app and helper app have the same code signing identity, otherwise return
        guard isValidClient(connection: newConnection) else {
            print("Rejected connection from unauthorized client")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: HelperToolProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }


    // Execute the shell command and reply with output.
    func authFV(username:String, password:String, withReply reply: @escaping (Bool) -> Void) {
        
        let stUsers = GetSecureTokenUserList()
        
        guard stUsers.contains(username) else {
            TCSLogWithMark("user \(username) is not a secure token user. Not enabling authenticated reboot.")
            reply(false)
            return

        }
        if filevaultAuth(username: username, password: password) == true {
            TCSLogWithMark("Successfully authenticated with FileVault using local admin.")
            reply(true)     
        }
        else {
            TCSLogWithMark("Error running fdesetup.")
            reply(false)
            
        }
    }

    func authFVAsAdmin(withReply reply: @escaping (Bool) -> Void) {
        do {
            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            
            if let adminUser = try userManager.adminCredentials(), !adminUser.username.isEmpty, !adminUser.password.isEmpty {
                authFV(username: adminUser.username, password: adminUser.password, withReply: reply)
            }
            else {
                TCSLogWithMark("no valid admin credentials found to unlock FV")
                reply(false)
            }
        }
        catch {
            TCSLogWithMark("Error with secret keeper:\(error)")
            reply(false)
            
        }
        

    }
    // Check that the codesigning matches between the main app and the helper app
    private func isValidClient(connection: NSXPCConnection) -> Bool {
        do {
            return try CodesignCheck.codeSigningMatches(pid: connection.processIdentifier)
        } catch {
            print("Helper code signing check failed with error: \(error)")
            return false
        }
    }
}

// Set up and start the XPC listener.
UserDefaults.standard.addSuite(named: "com.twocanoes.xcreds")

let delegate = HelperToolDelegate()
let listener = NSXPCListener(machServiceName: "com.twocanoes.FileVaultLoginHelper")
listener.delegate = delegate
listener.resume()
RunLoop.main.run()


