import Cocoa
import OpenDirectory

@objc class XCredsBaseMechanism: NSObject, XCredsMechanismProtocol {
    func reload() {
        fatalError()
    }

    let mechCallbacks: AuthorizationCallbacks
    let mechEngine: AuthorizationEngineRef
    let mech: MechanismRecord?
    @objc init(mechanism: UnsafePointer<MechanismRecord>) {
        TCSLogWithMark()
        self.mech = mechanism.pointee
        self.mechCallbacks = mechanism.pointee.fPlugin.pointee.fCallbacks.pointee
        self.mechEngine = mechanism.pointee.fEngine

        super.init()
        TCSLogWithMark("Setting up prefs")
        setupPrefs()

    }
    func run(){
        fatalError("superclass must implement")
    }
    func setupHints(fromCredentials credentials:Creds, password:String) -> SetupHintsResult {

        TCSLogWithMark("Checking for allow login preference")
        let tokenManager = TokenManager()
        let idTokenInfo = try? tokenManager.tokenInfo(fromCredentials: credentials)

        if let allowUsersClaim = DefaultsOverride.standardOverride.string(forKey: PrefKeys.allowUsersClaim.rawValue), let allowedUsersArray  = DefaultsOverride.standardOverride.array(forKey: PrefKeys.allowedUsersArray.rawValue) as? Array<String>, allowedUsersArray.count>0, let tokenInfo = idTokenInfo, let userValue = tokenInfo[allowUsersClaim] as? String {

            TCSLogWithMark("allowUsersClaim defined as \(allowUsersClaim) and allowedUsersArray as \(allowedUsersArray.debugDescription)")

            if allowedUsersArray.contains(userValue)==false {
                TCSLogWithMark("user is not allowed to login")
                //no need to send back message because failure will show it.

                denyLogin(message: nil)
                return .failure("The user \"\(userValue)\" is not allowed to login")
            }
            else {
                TCSLogWithMark("user allowed to login")

            }
        }


        do {

            let tokenManager = TokenManager()
            let idTokenInfo = try tokenManager.tokenInfo(fromCredentials: credentials)

            //no need to send back message because failure will show it.

            guard let idTokenInfo = idTokenInfo else {
                denyLogin(message: nil)
                return .failure("invalid idtoken")
            }

            let userInfoResult = tokenManager.setupUserAccountInfo(idTokenInfo: idTokenInfo)

            var userInfo:TokenManager.UserAccountInfo
            switch userInfoResult {

            case .success(let retUserAccountInfo):
                userInfo = retUserAccountInfo
            case .error(let message):
                //no need to send back message because failure will show it.

                denyLogin(message:nil)
                return .failure(message)
            }


            if  let allowedGroupsArray  = DefaultsOverride.standardOverride.array(forKey: PrefKeys.allowLoginIfMemberOfGroup.rawValue) as? Array<String>, allowedGroupsArray.count>0 {

                TCSLogWithMark("allowedGroupsArray as \(allowedGroupsArray.debugDescription)")

                var isMemberOfAllowedGroup=false
                userInfo.groups?.map({ group in
                    group.lowercased()
                }).forEach({ userGroup in
                    if allowedGroupsArray.contains(userGroup.lowercased()){
                        TCSLogWithMark("user is in group \(userGroup)")
                        isMemberOfAllowedGroup=true
                        return
                    }
                })

                if isMemberOfAllowedGroup==false {
                    TCSLogWithMark("user is not allowed to login. not in member of allowed group.")

                    return .failure("The user is not allowed to log in because they are not a member of an allowed group.")
                }
                else {
                    TCSLogWithMark("user allowed to login")

                }
            }

            if let firstname = userInfo.firstName {
                setHint(type: .firstName, hint: firstname as NSSecureCoding)
            }
            if let lastName = userInfo.lastName {
                setHint(type: .lastName, hint: lastName as NSSecureCoding)
            }
            if let username = userInfo.username {
                TCSLogWithMark("set shortname to \(username)")

                setHint(type: .user, hint: username as NSSecureCoding)
            }
            if let fullUsername = userInfo.fullUsername {
                setHint(type: .fullusername, hint: fullUsername as NSSecureCoding)
            }
            if let fullName = userInfo.fullName {
                setHint(type: .fullName, hint: fullName as NSSecureCoding)
            }
            if let groups = userInfo.groups {
                setHint(type: .groups, hint: groups as NSSecureCoding)
            }
            if let aliasName = userInfo.alias {
                setHint(type: .aliasName, hint: aliasName as NSSecureCoding)
            }
            if let kerberosPrincipalName = userInfo.kerberosPrincipalName {
                setHint(type: .kerberos_principal, hint: kerberosPrincipalName as NSSecureCoding)
            }
            if let uid = userInfo.uid {
                setHint(type: .uid, hint: uid as NSSecureCoding )
            }

            let findUserAndUpdatePasswordResult = tokenManager.findUserAndUpdatePassword(idTokenInfo: idTokenInfo, newPassword: password)
            guard let findUserAndUpdatePasswordResult = findUserAndUpdatePasswordResult else {
                //no need to send back message because failure will show it.

                denyLogin(message:nil)
                return .failure("could not find local user with findUserAndUpdatePassword")
            }


            switch findUserAndUpdatePasswordResult {

            case .successful(let username):
                userInfo.username = username
                break
            case .canceled:
                //no need to send back message because failure will show it.

                denyLogin(message:nil)
                return .failure("cancelled")
            case .createNewAccount:
                break
            case .error(let mesg):
                //no need to send back message because failure will show it.

                denyLogin(message:nil)
                return .failure(mesg)
            }
            guard let username = userInfo.username else {
                TCSLogErrorWithMark("username or password are not set")
                //no need to send back message because failure will show it.

                denyLogin(message:nil)
                return .failure("username or password are not set")
            }

            if  password.isEmpty {
                TCSLogWithMark("Empty password. Failing");
                let message = "Password not set. Verify username mapping in configuration is correct and you are not using passwordless login."
                //no need to send back message because failure will show it.
                denyLogin(message: nil)
                return .failure(message)

            }
            TCSLogWithMark("checking local password for username:\(username) and password length: \(password.count)");

            let  passwordCheckStatus =  PasswordUtils.isLocalPasswordValid(userName: username, userPass: password)

            switch passwordCheckStatus {
            case .success:
                TCSLogWithMark("Local password matches cloud password ")
            case .incorrectPassword:

                TCSLogWithMark("Sync password called.")

                let localAdmin = getHint(type: .localAdmin) as? LocalAdminCredentials

                if let localAdmin = localAdmin {

                    TCSLogWithMark("local admin set")
                }
                if getManagedPreference(key: .PasswordOverwriteSilent) as? Bool ?? false,
                   let localAdmin = localAdmin, localAdmin.hasEmptyValues()==false{
                    TCSLogWithMark("setting passwordOverwrite")
                    setHint(type: .passwordOverwrite, hint: true as NSSecureCoding)
                }
                else {

                    TCSLogWithMark()
                    let promptPasswordWindowController = VerifyLocalPasswordWindowController()

                    promptPasswordWindowController.showResetText=true
                    promptPasswordWindowController.showResetButton=true
                    if let localAdmin = localAdmin, localAdmin.hasEmptyValues()==false {
                        TCSLogWithMark("setting local admin and password")
                        promptPasswordWindowController.adminUsername = localAdmin.username
                        promptPasswordWindowController.adminPassword = localAdmin.password

                    }

                    switch  promptPasswordWindowController.promptForLocalAccountAndChangePassword(username: username, newPassword: password, shouldUpdatePassword: true) {


                    case .success(let enteredUsernamePassword):
                        TCSLogWithMark("setting original password to use to unlock keychain later")

                        if let enteredUsernamePassword = enteredUsernamePassword, !enteredUsernamePassword.password.isEmpty {
                            setHint(type: .existingLocalUserPassword, hint:password as NSSecureCoding  )
                        }

                    case .resetKeychainRequested:
                        TCSLogWithMark("resetKeychainRequested")

                        TCSLogWithMark("setting passwordOverwrite hint")
                        setHint(type: .passwordOverwrite, hint: true as NSSecureCoding)


                    case .userCancelled:
                        return .userCancelled
                    case .error(let errMsg):
                        TCSLogWithMark("Error prompting: \(errMsg)")
                        return .failure(errMsg)
                    }
                }

            case .accountDoesNotExist:
                TCSLogWithMark("user account doesn't exist yet")

            case .other(let mesg):
                TCSLogWithMark("password check error:\(mesg)")
                //no need to send back message because failure will show it.

                denyLogin(message:nil)
                return .failure(mesg)
            }
            TCSLogWithMark("passing username:\(username), password, and tokens")
            TCSLogWithMark("setting kAuthorizationEnvironmentUsername")
            setContextString(type: kAuthorizationEnvironmentUsername, value: username)
            TCSLogWithMark("setting kAuthorizationEnvironmentPassword")

            setContextString(type: kAuthorizationEnvironmentPassword, value: password)
            TCSLogWithMark("setting username")
            TCSLogWithMark("setting username to \(username)")
            setHint(type: .user, hint: username as NSSecureCoding)
            TCSLogWithMark("setting tokens.password")

            setHint(type: .pass, hint: password as NSSecureCoding)

            TCSLogWithMark("setting tokens")

            setHint(type: .tokens, hint: [credentials.idToken ?? "",credentials.refreshToken ?? "",credentials.accessToken ?? ""] as NSSecureCoding)
            TCSLogWithMark("calling allowLogin")
            XCredsAudit().loginWindowLogin(user:username)

            allowLogin()
            return .success
        }
        catch TokenManager.ProcessTokenResult.error(let msg){
            TCSLogWithMark("invalid idToken:\(msg)")
            denyLogin(message: nil)
            return .failure(msg)
        }
        catch {

            TCSLogWithMark("Error:\(error.localizedDescription)")
            //no need to send back message because failure will show it.

            denyLogin(message:nil)
            return .failure("credentialsUpdated error")

        }
    }
    func setupPrefs(){
        TCSLogWithMark()
        UserDefaults.standard.addSuite(named: "com.twocanoes.xcreds")
        let defaultsPath = Bundle(for: type(of: self)).path(forResource: "defaults", ofType: "plist")

        if let defaultsPath = defaultsPath {

            let defaultsDict = NSDictionary(contentsOfFile: defaultsPath)
            UserDefaults.standard.register(defaults: defaultsDict as! [String : Any])
        }
    }

    var xcredsPass: String? {
        get {
            guard let userPass = getHint(type: .pass) as? String else {
                return nil
            }
            os_log("Computed xcredsPass accessed: %@", log: noLoMechlog, type: .debug)
            return userPass
        }
    }
    var xcredsFirst: String? {
        get {
            guard let firstName = getHint(type: .firstName) as? String else {
                return ""
            }
            os_log("Computed firstName accessed: %{public}@", log: noLoMechlog, type: .debug, firstName)
            return firstName
        }
    }

    var xcredsLast: String? {
        get {
            guard let lastName = getHint(type: .lastName) as? String else {
                return ""
            }
            os_log("Computed lastName accessed: %{public}@", log: noLoMechlog, type: .debug, lastName)
            return lastName
        }
    }
    var xcredsUser: String? {
        get {
            guard let userName = getHint(type: .user) as? String else {
                TCSLogWithMark("no usernames")

                return nil
            }
            TCSLogWithMark("username is \(userName)")
            return userName
        }
    }
    var usernameContext: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = mechCallbacks.GetContextValue(
                mechEngine, kAuthorizationEnvironmentUsername, &flags, &value)

            if err != errSecSuccess {
                return nil
            }

            guard let username = NSString.init(bytes: value!.pointee.data!,
                                               length: value!.pointee.length,
                                               encoding: String.Encoding.utf8.rawValue)
                else { return nil }
            return username.trimmingCharacters(in:  CharacterSet.whitespaces.union(CharacterSet(["\0"])))
        }
    }
    var passwordContext: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = mechCallbacks.GetContextValue(
                mechEngine, kAuthorizationEnvironmentPassword, &flags, &value)

            if err != errSecSuccess {
                return nil
            }
            guard let pass = NSString.init(bytes: value!.pointee.data!,
                                           length: value!.pointee.length,
                                           encoding: String.Encoding.utf8.rawValue)
                else { return nil }

            return pass.trimmingCharacters(in:  CharacterSet.whitespaces.union(CharacterSet(["\0"])))


        }
    }
    func allowLogin() {
        TCSLogWithMark("================== Mech Complete ==================")

        let error = mechCallbacks.SetResult(mechEngine, .allow)

        if error != noErr {
            TCSLogErrorWithMark("Error: \(error)")
        }
    }

    // disallow login
    func denyLogin(message: String?) {
        TCSLogErrorWithMark("***************** DENYING LOGIN ********************");

        if let message = message {
            setStickyContextString(type: "ErrorMessage", value: message)
        }

        let error = mechCallbacks.SetResult(mechEngine, .deny)
        if error != noErr {
            TCSLogWithMark("Error: \(error)")

        }
    }

    func setHints(_ hints:[HintType:Any]){

        for hint in hints {
            if let hintValue = hint.value as? NSSecureCoding{
                setHint(type: hint.key, hint:hintValue )
            }
            else {
                TCSLogErrorWithMark("hint \(hint.key) does not conform to NSSecureCoding")

            }
        }
    }
    func setContextStrings(_ contentStrings: [String : String]){

        for contextString in contentStrings {
            setContextString(type: contextString.key, value:contextString.value)
        }
    }
    func setHint(type: HintType, hint: NSSecureCoding) {

        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: hint, requiringSecureCoding: true) else {
            TCSLogErrorWithMark("Login Set hint failed: cant archive data to a data object")
            return
        }

        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))

        let err = mechCallbacks.SetHintValue((mech?.fEngine)!, type.rawValue, &value)
        guard err == errSecSuccess else {
            TCSLogWithMark("XCred Login Set hint failed with: %{public}@")
            return
        }
    }
    func setHintData(type: HintType, data: Data) {
        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))

        let err = mechCallbacks.SetHintValue((mech?.fEngine)!, type.rawValue, &value)
        guard err == errSecSuccess else {
            TCSLogWithMark("XCred Login Set hint failed with: %{public}@")
            return
        }
    }
    var groups: [String]? {
        get {
            guard let userGroups = getHint(type: .groups) as? [String] else {
                os_log("groups value is empty", log: noLoMechlog, type: .debug)
                return nil
            }

            return userGroups
        }
    }

    func getHint(type: HintType) -> Any? {
        var value : UnsafePointer<AuthorizationValue>? = nil
        var err: OSStatus = noErr
        err = mechCallbacks.GetHintValue((mech?.fEngine)!, type.rawValue, &value)
        if err != errSecSuccess {
//            TCSLogWithMark("No hint retrieved for: \(type.rawValue)")
            return nil
        }

        let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)

        guard let result = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
            else {
                return nil
        }

        return result
    }

    /// Adds a new alias to an existing local record
    ///
    /// - Parameters:
    ///   - name: the shortname of the user to check as a `String`.
    ///   - alias: The password of the user to check as a `String`.
    /// - Returns: `true` if user:pass combo is valid, false if not.
    class func addAlias(name: String, alias: String) -> Bool {
        os_log("Checking for local username", log: noLoMechlog, type: .error)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return false
        }

        let isLocal = records.isEmpty ? false : true
        os_log("Results of local user check  %{public}@", log: noLoMechlog, type: .error, isLocal.description)

        if !isLocal {
            return isLocal
        }

        // now to update the alias
        do {
                if let currentAlias = try records.first?.values(forAttribute: kODAttributeTypeRecordName) as? [String] {
                    if !currentAlias.contains(alias) {
                      try records.first?.addValue(alias, toAttribute: kODAttributeTypeRecordName)
                    }
                } else {
                    try records.first?.addValue(alias, toAttribute: kODAttributeTypeRecordName)
                }
        } catch {
            os_log("Unable to add alias to record")
            return false
        }

        return true
    }

    /// Updates a timestamp on a local account
    ///
    /// - Parameters:
    ///   - name: the shortname of the user to check as a `String`.
    ///   - time: The time to add  as a `String`.
    /// - Returns: `true` if time attribute can be added, false if not.
    class func updateSignIn(name: String, time: AnyObject ) -> Bool {
        os_log("Checking for local username", log: noLoMechlog, type: .default)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return false
        }

        let isLocal = records.isEmpty ? false : true
        os_log("Results of local user check %{public}@", log: noLoMechlog, type: .default, isLocal.description)

        if !isLocal {
            return isLocal
        }

        // now to update the attribute

        do {
            try records.first?.setValue(time, forAttribute: kODAttributeNetworkSignIn)
            

        } catch {
            os_log("Unable to add sign in time to record", log: noLoMechlog, type: .error)
            return false
        }

        return true
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
            TCSLogWithMark("Set context value failed with: %{public}@")
            return
        }
    }
    func setStickyContextString(type: String, value: String) {
        TCSLogWithMark("Setting stick context \(type) value: \(value)")
        let tempdata = value + "\0"
        let data = tempdata.data(using: .utf8)
        var value = AuthorizationValue(length: (data?.count)!, data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        let err = mechCallbacks.SetContextValue((mech?.fEngine)!, type, .sticky, &value)
        guard err == errSecSuccess else {
            TCSLogWithMark("Set context value failed with: %{public}@")
            return
        }
    }


    func getContextString(type: String) -> String? {
        TCSLogWithMark()

        var value: UnsafePointer<AuthorizationValue>?
        var flags = AuthorizationContextFlags()
        let err = mech?.fPlugin.pointee.fCallbacks.pointee.GetContextValue((mech?.fEngine)!, type, &flags, &value)
        if err != errSecSuccess {
            TCSLogWithMark("No context string for \(type)")
            return nil
        }

        return String(bytesNoCopy: value!.pointee.data!, length: value!.pointee.length, encoding: .utf8, freeWhenDone: false)
    }

    func runDict() -> Dictionary<String, Any>? {
        do {


            let data =  NSData(contentsOfFile: "/tmp/xcredsrun") as? Data
            guard let data = data  else {
                return nil
            }

            let dict = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as? Dictionary<String, Any>
            return dict

        }
        catch {

            TCSLogWithMark("error creating xcrun dict: \(error)")
            return nil

        }


    }
    func updateRunDict(dict:Dictionary<String, Any>)  {
//        let emptyDictionary=Dictionary<String, Any>()
        do {


            let data = try NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: true)

            try data.write(to: URL.init(fileURLWithPath: "/tmp/xcredsrun"))

        }
        catch {

            TCSLogWithMark("error creating xcrun dict: \(error)")
        }
    }
    //MARK: - Directory Service Utilities

    /// Checks to see if a given user exits in the DSLocal OD node.
    ///
    /// - Parameter name: The shortname of the user to check as a `String`.
    /// - Returns: `true` if the user already exists locally. Otherwise `false`.
    class func checkForLocalUser(name: String) -> Bool {
        os_log("Checking for local username", log: noLoMechlog, type: .debug)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return false
        }
        let isLocal = records.isEmpty ? false : true
//        os_log("Results of local user check %{public}@", log: noLoMechlog, type: .debug, isLocal.description)
        return isLocal
    }



    /// Gets shortname from a UUID
    ///
    /// - Parameters:
    ///   - uuid: the uuid of the user to check as a `String`.
    /// - Returns: shortname of the user or nil.
    class func getShortname(uuid: String) -> String? {

        os_log("Checking for username from UUID", log: noLoMechlog, type: .debug)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeGUID, matchType: ODMatchType(kODMatchEqualTo), queryValues: uuid, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            _ = error.localizedDescription
//            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return nil
        }

        if records.count != 1 {
            return nil
        } else {
            return records.first?.recordName
        }
    }

}
