import Cocoa

protocol XCredsMechanismProtocol {
    func allowLogin()
    func denyLogin()
    func setContextString(type: String, value: String)
    func setHint(type: HintType, hint: Any)
}
@objc class XCredsBaseMechanism: NSObject, XCredsMechanismProtocol {
    let mechCallbacks: AuthorizationCallbacks
    let mechEngine: AuthorizationEngineRef
    let mech: MechanismRecord?
    @objc init(mechanism: UnsafePointer<MechanismRecord>) {
        TCSLog("\(#function) \(#file):\(#line)")
        self.mech = mechanism.pointee
        self.mechCallbacks = mechanism.pointee.fPlugin.pointee.fCallbacks.pointee
        self.mechEngine = mechanism.pointee.fEngine

        super.init()
        setupPrefs()

    }
    func run(){
        fatalError("superclass must implement")
    }
    func setupPrefs(){
        UserDefaults.standard.addSuite(named: "com.twocanoes.xcreds")
        let defaultsPath = Bundle(for: type(of: self)).path(forResource: "defaults", ofType: "plist")

        if let defaultsPath = defaultsPath {

            let defaultsDict = NSDictionary(contentsOfFile: defaultsPath)
            UserDefaults.standard.register(defaults: defaultsDict as! [String : Any])
        }


    }

    var xcredsUser: String? {
        get {
            guard let userName = getHint(type: .user) as? String else {
                return nil
            }
            TCSLog("Computed nomadUser accessed: %{public}@")
            return userName
        }
    }

    func allowLogin() {
        TCSLog("\(#function) \(#file):\(#line)")
        let error = mechCallbacks.SetResult(mechEngine, .allow)
        if error != noErr {
            TCSLog("Error: \(error)")
        }
    }

    // disallow login
    func denyLogin() {
        TCSLog("\(#function) \(#file):\(#line)")

        let error = mechCallbacks.SetResult(mechEngine, .deny)
        if error != noErr {
            TCSLog("Error: \(error)")

        }
    }

    func setHint(type: HintType, hint: Any) {
        guard (hint is String || hint is [String] || hint is Bool) else {
            TCSLog("Login Set hint failed: data type of hint is not supported")
            return
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: hint)
        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))

        let err = mechCallbacks.SetHintValue((mech?.fEngine)!, type.rawValue, &value)
        guard err == errSecSuccess else {
            TCSLog("NoMAD Login Set hint failed with: %{public}@")
            return
        }
    }

    func getHint(type: HintType) -> Any? {
        var value : UnsafePointer<AuthorizationValue>? = nil
        var err: OSStatus = noErr
        err = mechCallbacks.GetHintValue((mech?.fEngine)!, type.rawValue, &value)
        if err != errSecSuccess {
            TCSLog("Couldn't retrieve hint value: %{public}@")
            return nil
        }
        let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
        guard let result = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
            else {
            TCSLog("Couldn't unpack hint value: %{public}@")
                return nil
        }
        return result
    }

    /// Set one of the known `AuthorizationTags` values to be used during mechanism evaluation.
    ///
    /// - Parameters:
    ///   - type: A `String` constant from AuthorizationTags.h representing the value to set.
    ///   - value: A `String` value of the context value to set.
    func setContextString(type: String, value: String) {
        let tempdata = value + "\0"
        let data = tempdata.data(using: .utf8)
        var value = AuthorizationValue(length: (data?.count)!, data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        let err = mechCallbacks.SetContextValue((mech?.fEngine)!, type, .extractable, &value)
        guard err == errSecSuccess else {
            TCSLog("Set context value failed with: %{public}@")
            return
        }
    }

    func getContextString(type: String) -> String? {
        var value: UnsafePointer<AuthorizationValue>?
        var flags = AuthorizationContextFlags()
        let err = mechCallbacks.GetContextValue((mech?.fEngine)!, type, &flags, &value)
        if err != errSecSuccess {
            TCSLog("Couldn't retrieve context value: %{public}@")
            return nil
        }
        if type == "longname" {
            return String.init(bytesNoCopy: value!.pointee.data!, length: value!.pointee.length, encoding: .utf8, freeWhenDone: false)
        } else {
            let item = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
            TCSLog("get context error: %{public}@")
        }

        return nil
    }

}
