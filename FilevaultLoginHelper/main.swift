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
    func runCommand(username:String, password:String, withReply reply: @escaping (Bool) -> Void)
}

// XPC Communication setup
class HelperToolDelegate: NSObject, NSXPCListenerDelegate, HelperToolProtocol {
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
    func runCommand(username:String, password:String, withReply reply: @escaping (Bool) -> Void) {
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/fdesetup")
        process.arguments = ["authrestart", "-delayminutes","-1","-user",username,"-password",password]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            TCSLogWithMark("Failed to run command: \(error.localizedDescription)")
            reply(false)
            return
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        TCSLogWithMark(output.isEmpty ? "No output" : output)
        reply(false)

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


