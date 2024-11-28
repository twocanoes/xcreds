//
//  RunFileHelper.swift
//  XCreds
//
//  Created by Timothy Perfitt on 11/27/24.
//

import Foundation

class StateFileHelper {
    enum StateFileHelperError:Error {
    case FileCreationError
    }

    enum StateFileType {
        case returnType
        case delayType
    }

    func paths(_ fileType:StateFileType) -> (folderPath:String, filePath:String){
        var folderPath=""
        var filePath=""
        switch fileType {
        case .returnType:
            folderPath = "/usr/local/var/"
            filePath = "xcreds_return"

        case .delayType:
            folderPath = "/usr/local/var/"
            filePath = "xcreds_delay"
        }
        return (folderPath, filePath)
    }
    func createFile(_ fileType:StateFileType) throws  {
        TCSLogWithMark()

        
        let (folderPath, filePath) = paths(fileType)

        var attributes = [FileAttributeKey : Any]()
        attributes[.posixPermissions] = 0o770
        attributes[.ownerAccountID] = 92
        attributes[.groupOwnerAccountID] = 0


        if FileManager.default.fileExists(atPath: folderPath)==false {
            try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes:attributes)

        }
        attributes[.posixPermissions] = 0o660


        if FileManager.default.createFile(atPath: folderPath+filePath, contents: nil, attributes: attributes)==false {
            throw StateFileHelperError.FileCreationError
        }


    }
    func fileExists(_ fileType:StateFileType) -> Bool {
        TCSLogWithMark()
        let (folderPath, filePath) = paths(fileType)

        let fullPath = folderPath + filePath
        return FileManager.default.fileExists(atPath: fullPath)
    }
    func removeFile(_ fileType:StateFileType) throws {
        TCSLogWithMark()
        let (folderPath, filePath) = paths(fileType)

        let fullPath = folderPath + filePath
        if FileManager.default.fileExists(atPath: fullPath){
            return try FileManager.default.removeItem(atPath: fullPath)
        }

    }

    func killOrReboot(){

        if UserDefaults.standard.bool(forKey:PrefKeys.shouldUseKillWhenLoginWindowSwitching.rawValue)==true{
            TCSLogWithMark("killing loginwindow")

            do {
                try createFile(.delayType)
            }
            catch {
                TCSLog("could not create delay file")
            }

            let _ = cliTask("/usr/bin/killall loginwindow")

        }
        else {
            TCSLogWithMark("Reboot")
            let _ = cliTask("/sbin/reboot")

        }


    }
}
