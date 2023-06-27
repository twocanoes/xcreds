//
//  DefaultsOverride.swift
//  XCreds
//
//  Created by Timothy Perfitt on 5/21/23.
//

import Cocoa

public class DefaultsOverride: UserDefaults {

    static let standardOverride = DefaultsOverride()

    private override init?(suiteName suitename: String?) {
        TCSLogWithMark()
        super.init(suiteName: suitename)
        self.refreshCachedPrefs()
    }
    private convenience init() {
        TCSLogWithMark()
        self.init(suiteName: nil)!
    }
    var cachedPrefs=Dictionary<String, Any>()
    @objc func refreshCachedPrefs()  {
        TCSLogWithMark()
        cachedPrefs=Dictionary()
        let prefScriptPath = UserDefaults.standard.string(forKey: PrefKeys.settingsOverrideScriptPath.rawValue)
        guard let prefScriptPath = prefScriptPath else {
            TCSLogWithMark("no override defined")
            return
        }
        TCSLogErrorWithMark("Pref script defined at \(prefScriptPath)")
        if FileManager.default.fileExists(atPath:prefScriptPath)==false{
            TCSLogErrorWithMark("Pref script defined but does not exist")
            return
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: prefScriptPath)

            guard let ownerID=attributes[.ownerAccountID] as? NSNumber else {
                TCSLogErrorWithMark("Could not get owner id")
                return
            }
            guard let permission = attributes[.posixPermissions] as? NSNumber else

            {
                TCSLogErrorWithMark("Could not get permission")
                return

            }
            if ownerID.uintValue != 0 {
                TCSLogErrorWithMark("override script is not owned by root. not running: \(ownerID.debugDescription)")
                return
            }

            let unixPermissions = permission.int16Value

            if unixPermissions & 0x3f != 0 {
                TCSLogErrorWithMark("override script cannot be accessible by anyone besides root. not running: \(unixPermissions)")
                return

            }
            
            let scriptRes=cliTask(prefScriptPath)

            if scriptRes.count==0{
                TCSLogErrorWithMark("script did not return anything")
                return
            }
            TCSLogWithMark()
            guard let rawData = scriptRes.data(using: .utf8) else {
                TCSLogErrorWithMark("could not convert raw data");
                return
            }
            var format: PropertyListSerialization.PropertyListFormat = .xml

            TCSLogWithMark()

            do {
                TCSLogWithMark()

                /*
                 guard  let propertyListObject = try PropertyListSerialization.propertyList(from: rawData, options: [], format: &format)  else {
                     TCSLogErrorWithMark("could not turn to plist")
                     return
                 }


                 */
                let propertyListObject = try PropertyListSerialization.propertyList(from: rawData, options: [], format: &format)

                if let propertyListObject = propertyListObject as? [String: Any] {
                    cachedPrefs=propertyListObject

                }
                else {
                    TCSLogWithMark("Could not convert to plist")
                }
            } catch {
                TCSLogErrorWithMark("Error converting script to property list: \(scriptRes)")
                return
            }
            TCSLogWithMark()

        }
        
        catch {
            
            TCSLogErrorWithMark(error.localizedDescription)
        }
    }
    override public func string(forKey defaultName: String) -> String? {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName] as? String{
            return defaultName
        }
        return UserDefaults.standard.string(forKey: defaultName)
    }
    override public func object(forKey defaultName: String) -> Any? {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName]{
            return defaultName
        }

        return UserDefaults.standard.object(forKey: defaultName)
    }

    override public func array(forKey defaultName: String) -> [Any]? {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName] as? [Any]{
            return defaultName
        }

        return UserDefaults.standard.array(forKey: defaultName)
    }
    override public func data(forKey defaultName: String) -> Data? {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName] as? Data {
            return defaultName
        }

        return UserDefaults.standard.data(forKey: defaultName)
    }
    override public func integer(forKey defaultName: String) -> Int {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName] as? Int {
            return defaultName
        }

        return UserDefaults.standard.integer(forKey: defaultName)
    }
    override public func float(forKey defaultName: String) -> Float {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName] as? Float {
            return defaultName
        }

        return UserDefaults.standard.float(forKey: defaultName)
    }
    override public func double(forKey defaultName: String) -> Double {

        if let defaultName = cachedPrefs[defaultName] as? Double {
            return defaultName
        }

        return UserDefaults.standard.double(forKey: defaultName)
    }
    override public func bool(forKey defaultName: String) -> Bool {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName] as? Bool {
            return defaultName
        }

        return UserDefaults.standard.bool(forKey: defaultName)
    }
    override public func url(forKey defaultName: String) -> URL? {
        TCSLogWithMark()

        if let defaultName = cachedPrefs[defaultName] as? URL {
            return defaultName
        }

        return UserDefaults.standard.url(forKey: defaultName)
    }



}
