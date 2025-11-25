//
//  GoogleLDAP.swift
//  XCreds
//
//  Created by Timothy Perfitt on 11/24/25.
//

import Foundation
public class GoogleLDAP:NSObject {
    
    enum PasswordCheckResult {
        case PasswordValid
        case PasswordInvalid
        case OtherError
        
    }
    func verifyPasswordGoogleLDAP(username:String, password:String) -> PasswordCheckResult{
   
        var arguments: [String] = [String]()
        arguments.append("-LLL")
        arguments.append("-H"); arguments.append("ldaps://ldap.google.com")
        arguments.append("-y"); arguments.append("/dev/stdin")

        arguments.append("-b"); arguments.append("dc=\(username)")
        arguments.append("-D"); arguments.append(username)
        arguments.append(username)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ldapsearch")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let stdInPipe = Pipe()
        
        process.standardInput=stdInPipe
        do {
            process.environment=["LDAPTLS_IDENTITY":"LDAP Client"]
            try process.run()
            stdInPipe.fileHandleForWriting.write(Data(password.utf8))
            try? stdInPipe.fileHandleForWriting.close()
            process.waitUntilExit()
        } catch {
            TCSLogWithMark("Failed to run command: \(error.localizedDescription)")
            return PasswordCheckResult.OtherError

        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        TCSLogWithMark(output.isEmpty ? "No output" : output)
        
        switch process.terminationStatus {
        case 0:
            return PasswordCheckResult.PasswordValid
        case 49:
            return PasswordCheckResult.PasswordInvalid

        default:
            return PasswordCheckResult.OtherError

        }
        
    }
}

