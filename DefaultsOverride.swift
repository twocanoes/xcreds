//
//  DefaultsOverride.swift
//  XCreds
//
//  Created by Timothy Perfitt on 5/21/23.
//

import Cocoa

class DefaultsOverride: UserDefaults {

    var cachedPrefs=Dictionary<String,Any>()
    func refreshCachedPrefs()  {
        cachedPrefs=Dictionary()
        let prefScriptPath = super.string(forKey: PrefKeys.settingsOverrideScriptPath.rawValue)
        if let prefScriptPath = prefScriptPath {
            TCSLogErrorWithMark("Pref script defined at \(prefScriptPath)")
            if FileManager.default.fileExists(atPath:prefScriptPath)==false{
                TCSLogErrorWithMark("Pref script defined but does not exist")
                return
            }

            if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: prefScriptPath), let ownerID=attributes[.ownerAccountID] as? NSNumber,
               let permission = attributes[.posixPermissions] as? NSNumber
            {

                if ownerID.uintValue != 0 {
                    TCSLogErrorWithMark("override script is not owned by root. not running")
                    return
                }

                let unixPermissions = permission.int16Value

                if unixPermissions & 0x15 != 0 {
                    TCSLogErrorWithMark("override script cannot be writable by anyone besides root. not running.")
                    return

                }
                let scriptRes=cliTask(prefScriptPath)

                if scriptRes.count>0{
                    let rawData = scriptRes.data(using: .utf8)
                    var format: PropertyListSerialization.PropertyListFormat = .xml


                    var propertyListObject = [ String: [String]]()

                    do {
                        propertyListObject = try PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
                    } catch {
                        TCSLogErrorWithMark("Error converting script to property list: \(scriptRes)")
                        return
                    }
                    cachedPrefs=propertyListObject

                }

            }

        }


    }
    override func string(forKey defaultName: String) -> String? {
        return super.string(forKey: defaultName)
    }
    override func object(forKey defaultName: String) -> Any? {
        return super.object(forKey: defaultName)
    }

    override func array(forKey defaultName: String) -> [Any]? {
        return super.array(forKey: defaultName)
    }
    override func data(forKey defaultName: String) -> Data? {
        return super.data(forKey: defaultName)
    }
    override func integer(forKey defaultName: String) -> Int {
        return super.integer(forKey: defaultName)
    }
    override func float(forKey defaultName: String) -> Float {
        return super.float(forKey: defaultName)
    }
    override func double(forKey defaultName: String) -> Double {
        return super.double(forKey: defaultName)
    }
    override func bool(forKey defaultName: String) -> Bool {
        return super.bool(forKey: defaultName)
    }
    override func url(forKey defaultName: String) -> URL? {
        return super.url(forKey: defaultName)
    }



}
