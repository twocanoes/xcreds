//
//  AppDelegate.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Cocoa
import ArgumentParser
import CryptoKit
import CryptoTokenKit

@main
struct xcreds:ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "Command line interface for XCreds.",
        subcommands: [Status.self,ImportRFIDUsers.self, ShowTemplate.self,SetRFIDUser.self, ShowRFIDUser.self,ShowRFIDUsers.self, RemoveRFIDUser.self,SetAdminUser.self,ShowAdminUser.self, ClearAdminUser.self,ClearRFIDUsers.self, ListReaders.self,RFIDListener.self, RunApp.self],
        defaultSubcommand: RunApp.self)

}
extension xcreds {
    struct Status:ParsableCommand {
        @Flag(help:"JSON output") var json:Bool = false
        static var configuration = CommandConfiguration(abstract: "Get status of XCreds")
        @Argument(parsing: .allUnrecognized)


        var other: [String] = []

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            struct XCredsInfo:Codable {
                var consoleRights:[String]?
                var userInfo:[String:Dictionary<String,String>]?
                var oidcUsers:[[String:String]]?
                var xcredsVersion:String=""
                var xcredsBuild:String=""

                var xcredLicenseStatus:String=""
                var xcredsLicenseDaysRemaining:String=""
                init() {
                    let bundle = Bundle.findBundleWithName(name: "XCreds")
                    if let bundle = bundle {
                        let infoPlist = bundle.infoDictionary
                        if let infoPlist = infoPlist, let buildFromInfoPlist = infoPlist["CFBundleVersion"] as? String, let versionFromInfoPlist = infoPlist["CFBundleShortVersionString"] as? String {
                            xcredsBuild = buildFromInfoPlist
                            xcredsVersion = versionFromInfoPlist
                        }
                    }

                    let licenseState = LicenseChecker().currentLicenseState()

                    switch licenseState {

                    case .valid(let secRemaining):
                        let daysRemaining = Int(secRemaining/(24*60*60))

                        xcredLicenseStatus="Valid"
                        xcredsLicenseDaysRemaining=String(format:"%i",daysRemaining)
                    case .invalid:
                        xcredLicenseStatus="Invalid"

                    case .trial(_):
                        xcredLicenseStatus="Trial"

                    case .trialExpired:
                        xcredLicenseStatus="trialExpired"

                    case .expired:
                        xcredLicenseStatus="expired"

                    }
                }

            }

            enum UserKeys:String {
                case realName="dsAttrTypeStandard:RealName"
                case homeDirectory="dsAttrTypeStandard:NFSHomeDirectory"
                case recordName="dsAttrTypeStandard:RecordName"
                case authenticationAuthority="dsAttrTypeStandard:AuthenticationAuthority"
                case oidcUsername="dsAttrTypeNative:_xcreds_oidc_username"
                case primaryGID="dsAttrTypeStandard:PrimaryGroupID"
                case shell="dsAttrTypeStandard:UserShell"
                case uid="dsAttrTypeStandard:UniqueID"
            }

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }

            var info = XCredsInfo()

            let rightsInfo =  AuthorizationDBManager().consoleRights()
            var oidcUsers = [[String:String]]()
            var usersResult=[String:Dictionary<String, String>]()



            info.consoleRights = rightsInfo

            if !json{


                print("----- XCreds Info -----")
                print("     " + "XCreds Version:" + info.xcredsVersion)
                print("     " + "XCreds Build number:" + info.xcredsBuild)
                print("     " + "License Status:" + info.xcredLicenseStatus)
                if info.xcredLicenseStatus.isEmpty==false {
                    print("     " + "Days Remaining:" + info.xcredsLicenseDaysRemaining)

                }
                print("----- Last User Info -----")

                if let loginWindowAuditRecord = XCredsAudit().auditRecord(path: "/var/db/securityagent/.xcredsaudit") {

                    let auditDict = XCredsAudit().auditRecordDictionary(loginWindowAuditRecord)
                    for (k,v) in auditDict{
                        if !json {
                            print("     " + k +  ": " + v)
                        }
                    }

                }


                print("----- CONSOLE RIGHTS -----")
                for thisRight in rightsInfo {

                    print("     " + thisRight)
                }
            }
            do {
                let users = try PasswordUtils().getAllNonSystemUsers()
                var userDetailsInfo = [String:String]()
                if !json {
                    print("----- OIDC User Info -----")
                }
                for user in users {
                    let userDetails = try? user.recordDetails(forAttributes: nil)
                    if let userDetails = userDetails {
                        if let homeDirArray = userDetails["dsAttrTypeStandard:NFSHomeDirectory"] as? Array<String>, homeDirArray.count>0{
                            let homeDir = homeDirArray[0]
                            if let auditRecord = XCredsAudit().auditRecord(path: homeDir+"/.xcredsaudit") {

                                let auditDict = XCredsAudit().auditRecordDictionary(auditRecord)
                                for (k,v) in auditDict{
                                    userDetailsInfo[k] = v
                                    if !json {
                                        print("          " + k +  ": " + v)


                                    }
                                }

                            }

                        }

                        for userDetail in userDetails {

                            if let key = userDetail.key as? String,let _ = UserKeys(rawValue: key), let values = userDetail.value as? [String]

                                {
                                let value = values.joined(separator: "")
                                userDetailsInfo[key] = value
                                if key == UserKeys.oidcUsername.rawValue {
                                    oidcUsers.append(["localUsername":user.recordName,"oidcUsername":value])
                                    if !json {
                                        print("     " + user.recordName)
                                        print("          localUsername" + ":" + user.recordName)
                                        print("          oidcUsername" +  ": " + value)
                                    }
                                }
                            }

                        }
                    }
                    usersResult[user.recordName] = userDetailsInfo

                }
                info.oidcUsers=oidcUsers
                info.userInfo = usersResult
                let encoder =  JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonOutput = try encoder.encode(info)
                if json {
                    print(String(data: jsonOutput, encoding: .utf8)!)
                }
            }
            catch {
                print(error)
            }

            return
        }



    }
}
extension xcreds {
    struct ListReaders:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "List currently plugged in RFID readers.")

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            let slotNames = TKSmartCardSlotManager.default?.slotNames

            guard let slotNames = slotNames, slotNames.count>0 else {
                print("No readers found")
                return
            }

            for slot in slotNames {

                print(slot)
            }
            return
        }



    }
}


extension xcreds {
    struct RFIDListener:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Listen and print the RFID of scanned cards.")

        @Option(help: "reader name")
        var readerName:String

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            print("press control-c to exit")

            let watcher = TKTokenWatcher()
            watcher.setInsertionHandler({ tokenID in
                print("card inserted")

                watcher.addRemovalHandler({ tokenID in
                    print("card removed")
                }, forTokenID: tokenID)

                let slotNames = TKSmartCardSlotManager.default?.slotNames

                guard let slotNames = slotNames, slotNames.count>0 else {
                    return
                }

                if slotNames.contains(readerName) == false {

                    print("reader \(readerName) not found")
                    NSApplication.shared.terminate(self)

                }



                let slot = TKSmartCardSlotManager.default?.slotNamed(readerName)
                guard let tkSmartCard = slot?.makeSmartCard() else {
                    print("error finding smartcard in reader \(readerName). Make sure the card was inserted into this reader.")
                    return
                }

                let builtInReader = CCIDCardReader(tkSmartCard: tkSmartCard)
                let returnData = builtInReader.sendAPDU(cla: 0xFF, ins: 0xCA, p1: 0, p2: 0, data: nil)
                if let returnData=returnData, returnData.count>2{
                    DispatchQueue.main.async {
                        let hex=returnData[0...returnData.count-3].hexEncodedString()
                        print(hex)
                    }
                }

            })

            RunLoop.main.run()

        }
    }
}

extension xcreds {
    struct RunApp:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Start app normally.")
            @Argument(parsing: .allUnrecognized)
            var other: [String] = []

        func run() throws {


            //used to register ccid reader as root. no idea why
            //this is needed.
            if other.contains("-r") {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+5) {
                    NSApplication.shared.terminate(self)
                }
            }

            let app = NSApplication.shared

            let appDelegate = AppDelegate()
            app.delegate = appDelegate
            _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        }

    }
}

extension xcreds {
    struct ShowAdminUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show currently set admin user. Used for resetting keychain.")

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }
            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            if let adminUser = try userManager.adminCredentials(), !adminUser.username.isEmpty {
                print("\(adminUser.username)")

            }
            else {
                print("admin user not set")
            }

        }
    }
}
extension xcreds {
    struct ClearRFIDUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Clear rfid user.")

        @Option(help: "Username to remove")
        var username:String

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }

            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)

            do {
                let res = try userManager.removeUIDUser(username: username)

                if res == true {
                    print("RFID user removed.")

                }
                else {
                    print("RFID User could not be removed. Please check the username and try again")
                }

            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}
extension xcreds {
    struct ClearRFIDUsers:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Clear all users. Does not clear the admin user.")

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }

            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            try userManager.clearUIDUsers()
        }
    }
}

extension xcreds {
    struct ClearAdminUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Clear the current admin user used for resetting keychain.")

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }
            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            try userManager.updateLocalAdminCredentials(user: SecretKeeperUser(fullName: "", username: "", password: "", uid: -1, rfidUID: Data(), pin: nil))

        }
    }
}
extension xcreds {
    struct SetAdminUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Set the current admin user used for resetting keychain.")

        @Option(help: "Update Admin username")
        var adminusername:String

        @Option(help: "Update Admin password")
        var adminpassword:String

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)
            }

            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            try userManager.updateLocalAdminCredentials(user: SecretKeeperUser(fullName: "", username: adminusername, password: adminpassword, uid: NSNumber(value: -1), rfidUID: Data(), pin: nil))
        }

    }
}
extension xcreds {
    struct SetRFIDUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Add an RFID user.")
        @Argument(parsing: .allUnrecognized)
        var other: [String] = []

        @Option(help: "Update Fullname")
        var fullname:String

        @Option(help: "Update username")
        var username:String

        @Option(help: "Update Password")
        var password:String

        @Option(help: "Update UID")
        var uid:String = ""

        @Option(help: "Update RFID-uid")
        var rfiduid:String

        @Option(help: "PIN")
        var pin:String?


        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }

            do {
                if !username.isEmpty && !password.isEmpty && !fullname.isEmpty && !rfiduid.isEmpty{


                    let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")

                    let userManager = UserSecretManager(secretKeeper: secretKeeper)
                    guard let rfidUIDData = Data(fromHexEncodedString: rfiduid) else {
                        print("invalid rfid. Must be hex with no 0x prefix")
                        return

                    }


                    try userManager.setUIDUser(fullName: fullname, rfidUID: rfidUIDData, username: username, password: password, uid: NSNumber(value: Int(uid) ?? -1), pin: pin)
                    print("user set. If this Mac system is at the XCreds login window, please restart (or log in and log out) to use the new user.")
                }
            }
            catch {
                print(error.localizedDescription)

            }
        }

    }
}
extension xcreds {
    struct ShowRFIDUsers:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show RFID users.")

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }
            do {
                let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
                let userManager = UserSecretManager(secretKeeper: secretKeeper)
                let users = try userManager.uidUsers()

                print("Full Name:Username:UserID:Requires PIN")

                guard let rfidUsers = users.userDict else {
                    return
                }
                for currKey in rfidUsers.keys{
                    if let user = rfidUsers[currKey], let fullname = user.fullName,let _ = rfidUsers[currKey]?.password {
                        print("\(fullname):\(user.username):\(user.userUID):\(user.requiresPIN==true ? "Y":"N")")

                    }
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
}


extension xcreds {
    struct ShowRFIDUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show RFID user.")


        @Option(help: "RFID-uid in hex with no 0x in front.")
        var rfidUID:String

        @Option(help: "PIN")
        var pin:String?

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }
            do {
                let rfidUidData = Data(fromHexEncodedString: rfidUID)
                guard let rfidUidData = rfidUidData else {
                    print("bad RFID rfidUidData")

                    return
                }

                let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
                let userManager = UserSecretManager(secretKeeper: secretKeeper)
                guard let user = try userManager.uidUser(uid: rfidUidData) else {
                    print("user not found")
                    return
                }

                if user.requiresPIN == true && pin == nil {

                    print("you must enter a PIN for this user")
                    return
                }
                let password = try PasswordCryptor().passwordDecrypt(encryptedDataWithSalt: user.password, rfidUID: rfidUidData, pin:pin)

                if password.count>0 {

                    print("Fullname: \(user.fullName ?? "No full name"), Username:\(user.username), UID:\(user.userUID)")
                }
                else {
                    print("no password set for user \(user.username)")
                }

            }
            catch {
                print("failed to find user, valid PIN, or both")
            }


        }
    }
}
extension xcreds {
    struct RemoveRFIDUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Remove RFID user by rfid-uid.")


        @Option(help: "RFID-uid in hex with no 0x in front.")
        var rfidUID:String


        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }
            do {
                let rfidUidData = Data(fromHexEncodedString: rfidUID)
                guard let rfidUidData = rfidUidData else {
                    print("bad RFID rfidUidData")

                    return
                }

                let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
                let userManager = UserSecretManager(secretKeeper: secretKeeper)
                guard let _ = try userManager.uidUser(uid: rfidUidData) else {
                    print("user not found")
                    return
                }
                if try userManager.removeUIDUser(uid: rfidUidData) == false {
                    print("user could not be removed")
                }
                else {
                    print("user removed. If this Mac system is at the XCreds login window, please restart (or log in and log out) to prevent the user from logging in.")


                }

            }
            catch {
                print(error.localizedDescription)
            }


        }
    }
}





extension xcreds {
    struct ImportRFIDUsers:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Import users from a CSV for RFID login. Format:Full Name,Username,Password,RFID-UID,PIN,UID. PIN and UID can be left blank. All imported user data is encrypted and stored in a file located in /usr/local/var/twocanoes. The file is only readable by root.")


        @Option(help: "file")
        var file:String

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true


            if !file.isEmpty {
                if FileManager.default.fileExists(atPath: file)==false {
                    print("\(file) does not exist.")
                }
                do {
                    let contentsOfFile = try String(contentsOfFile: file, encoding: .windowsCP1250)

                    let rfidUsers=RFIDUsers(rfidUsers: [:])
                    let lineArray = contentsOfFile.components(separatedBy:"\n")

                    let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")

                    let userManager = UserSecretManager(secretKeeper: secretKeeper)
                    var count = 0
                    for line in lineArray {
                        if line.count==0 {
                            continue
                        }
                        let userInfo = line.components(separatedBy: ",")
                        if userInfo.count != 6 {
                            print("invalid line. skipping. Line:\"\(line)\"")
                            continue
                        }
                        let fullname = userInfo[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        if fullname == "Full Name" {
                            print("skipping header")
                            continue
                        }
                        var pin:String?
                        let username = userInfo[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let password = userInfo[2].trimmingCharacters(in: .whitespacesAndNewlines)
                        let rfidUid = userInfo[3].trimmingCharacters(in: .whitespacesAndNewlines)
                        let pinString = userInfo[4].trimmingCharacters(in: .whitespacesAndNewlines)

                        if pinString.isEmpty {
                            pin=nil
                        }
                        else {
                            pin = pinString
                        }

                        let uid = Int(userInfo[5].trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
                        print("importing \(rfidUid):\(fullname):\(username):\(uid)")


                        guard let rfidUidData = rfidUid.data(using: .hexadecimal) else {

                            print("invalid uid")
                            return
                        }
                        try userManager.setUIDUser(fullName: fullname, rfidUID: rfidUidData, username: username, password: password, uid: NSNumber(value: Int(uid)), pin: pin)

//                        let (hashedUID,salt) = try PasswordCryptor().hashSecretWithKeyStretchingAndSalt(secret: rfidUidData,salt: nil)
//
//                        print(rfidUidData.hexEncodedString()) 
//                        print(hashedUID.hexEncodedString())
//                        print(salt.hexEncodedString())
//                        
//                        rfidUsers.userDict?[salt+hashedUID] = try SecretKeeperUser(fullName: fullname, username: username, password: password, uid: NSNumber(value: Int(uid)), rfidUID: rfidUidData, pin: pin)
                        count += 1
                    }

//                    try userManager.setUIDUsers(rfidUsers)
                    print("\(count) users imported. If this Mac system is at the XCreds login window, please restart (or log in and log out) to use the new users.")
                }
                catch {
                    print("\(file) cannot be read. \(error)")

                }
            }

        }

    }
    struct ShowTemplate:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Template for importing RFID users. The header row is optional. PIN and UID can be left blank but must contain commas with empty values as show below. John Doe has all values, Sam Doe does not have a PIN, and Jane Doe does not have a PIN or a UID (UID will be automatically selected when the user account is created)")

        func run() throws {
            TCSUnifiedLogger.shared().suppressDebug=true

            print("Full Name,Username,Password,RFID-UID,PIN,UID")
            print("John Doe,jdoe,password%1!,00124565,000000,601")
            print("Sam Doe,sam,password@3^,DEADBEEF,,602")
            print("Jane Doe,jane,password@2^,08091A1B1C1D1E,,")


        }

    }

}


class AppDelegate: NSObject, NSApplicationDelegate, DSQueryable {

    @IBOutlet weak var loginPasswordWindow: NSWindow!
    @IBOutlet var window: NSWindow!
    var mainController:MainController?
    var screenIsLocked=true
    var isDisplayAsleep=true
    var waitForScreenToWake=false
    @IBOutlet var shareMounterMenu: ShareMounterMenu?
    @IBOutlet weak var statusMenu: NSMenu!
    var shareMenu:NSMenu?
    var statusBarItem:NSStatusItem?
    var watcher: TKTokenWatcher?

    func updateShareMenu(adUser:ADUserRecord){
        shareMounterMenu?.shareMounter?.adUserRecord = adUser
        shareMounterMenu?.updateShares(connected: true)
        shareMenu = shareMounterMenu?.buildMenu(connected: true)

        if let sharesMenuItem = statusMenu.item(withTag: StatusMenuController.StatusMenuItemType.SharesMenuItem.rawValue) {

            if shareMenu?.items.count==0{
                sharesMenuItem.isHidden=true
            }
            else {
                sharesMenuItem.isHidden=false
                statusMenu.setSubmenu(shareMenu, for:sharesMenuItem )
            }

        }

    }
    func updateStatusMenuExpiration(_ expires:Date?) {

        ///TODO: implement edge cases
        return
//        DispatchQueue.main.async {
//
//            TCSLogWithMark()
//
//            if let expires = expires {
//                let daysToGo = Int(abs(expires.timeIntervalSinceNow)/86400)
//
//                self.statusBarItem?.button?.title="\(daysToGo)d"
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateStyle = .medium
//                dateFormatter.timeStyle = .short
//
//
//                self.statusBarItem?.button?.toolTip = dateFormatter.string(from: expires as Date)
//
//            }
//            else {
//                self.statusBarItem?.button?.title=""
//                self.statusBarItem?.button?.toolTip = ""
//            }
//
//
//        }
    }
    func updateStatusMenuIcon(showDot:Bool){


        DispatchQueue.main.async {

            TCSLogWithMark()
            if showDot==true {
                TCSLogWithMark("showing with dot")

                if let iconData=DefaultsOverride.standardOverride.data(forKey: PrefKeys.menuItemIconCheckedData.rawValue), let image = NSImage(data: iconData) {
                    image.size=NSMakeSize(16, 16)
                    self.statusBarItem?.button?.image=image

                }
                else {
                    self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon check")
                }

            }
            else {
                TCSLogWithMark("showing without dot")
                if let iconData=DefaultsOverride.standardOverride.data(forKey: PrefKeys.menuItemIconData.rawValue), let image = NSImage(data: iconData) {
                    image.size=NSMakeSize(16, 16)

                    self.statusBarItem?.button?.image=image

                }
                else {
                    self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon")
                }
            }
        }
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        NetworkMonitor.shared.startMonitoring()
        updatePrefsFromDS()
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.isVisible=true
        statusBarItem?.menu = statusMenu



        if let iconData=DefaultsOverride.standardOverride.data(forKey: PrefKeys.menuItemIconData.rawValue), let image = NSImage(data: iconData) {
            image.size=NSMakeSize(16, 16)

            self.statusBarItem?.button?.image=image
        }
        else {
            self.statusBarItem?.button?.image=NSImage(named: "xcreds menu icon")
        }
        let shareMounter = ShareMounter()

        shareMounterMenu = ShareMounterMenu()
        shareMounterMenu?.shareMounter = shareMounter
        shareMounterMenu?.updateShares(connected: true)
        shareMenu = shareMounterMenu?.buildMenu(connected: true)
//
        let defaultsPath = Bundle.main.path(forResource: "defaults", ofType: "plist")

        if let defaultsPath = defaultsPath {

            let defaultsDict = NSDictionary(contentsOfFile: defaultsPath)
            TCSLogWithMark()
            DefaultsOverride.standardOverride.register(defaults: defaultsDict as! [String : Any])
        }


        let infoPlist = Bundle.main.infoDictionary

        if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"] {
            TCSLogWithMark("Build \(build)")

        }
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenLocked(_:)), name:NSNotification.Name("com.apple.screenIsLocked") , object: nil)

        DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenUnlocked(_:)), name:NSNotification.Name("com.apple.screenIsUnlocked") , object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidSleep(_:)), name:NSWorkspace.screensDidSleepNotification , object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenDidWake(_:)), name:NSWorkspace.screensDidWakeNotification , object: nil)

        DispatchQueue.global().async{

            if var autofillAppPath = Bundle.main.path(forResource: "XCreds Login Autofill", ofType: "app"){
                autofillAppPath = autofillAppPath + "/Contents/MacOS/XCreds Login Autofill"
                if FileManager.default.fileExists(atPath: autofillAppPath){

                    let _ = TCTaskHelper.shared().runCommand(autofillAppPath, withOptions:["-r"] )
                    TCSLogWithMark("autofill registered")
                }
            }
        }
        if UserDefaults.standard.bool(forKey: "checkForUpdates")==true{
            checkForUpdates()
        }
        mainController = MainController()
        mainController?.setup()

    }
    func checkForUpdates() {
        let thisAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let thisAppBundleID = Bundle.main.bundleIdentifier

        if let thisAppVersion = thisAppVersion, let thisAppBundleID = thisAppBundleID,
           let thisAppVersionFloat = Float(thisAppVersion){

            VersionCheck.versionForIdentifier(identifier: thisAppBundleID, version: thisAppVersion) { isSuccess, version in

                if let versionFloat = Float(version),!thisAppVersion.isEmpty, !version.isEmpty, thisAppVersionFloat < versionFloat {
                    TCSLogErrorWithMark("New version available: \(thisAppVersion) < \(version)")
                }
            }
        }
    }
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    @objc func screenUnlocked(_ sender:Any) {
        TCSLogWithMark()
        screenIsLocked=false

    }
    @objc func screenLocked(_ sender:Any) {
        TCSLogWithMark()
        screenIsLocked=true
        if isDisplayAsleep==true{

            waitForScreenToWake=true
        }
        else {
            waitForScreenToWake=false
            switchToLoginWindow()        }

    }
    @objc func screenDidSleep(_ sender:Any) {
        TCSLogWithMark()
        isDisplayAsleep=true
    }
    @objc func screenDidWake(_ sender:Any) {
        TCSLogWithMark()
        isDisplayAsleep=false

        if waitForScreenToWake==true {
            waitForScreenToWake=false
            switchToLoginWindow()
        }
    }
    func switchToLoginWindow()  {
        if DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldSwitchToLoginWindowWhenLocked.rawValue)==true{
            TCSLoginWindowUtilities().switchToLoginWindow(self)
        }

    }

    func updatePrefsFromDS(){
        if let currentUser = PasswordUtils.getCurrentConsoleUserRecord() {

            do {
                let attributesArray = try currentUser.recordDetails(forAttributes: nil)
                for currAttribute in attributesArray {
                    if let key = currAttribute.key as? String, key.hasPrefix("dsAttrTypeNative:_xcreds"), let value = currAttribute.value as? Array<String>, let lastValue = value.last {
                        let components = key.components(separatedBy: ":")
                        if let strippedKey = components.last{
                            UserDefaults.standard.set(lastValue, forKey:strippedKey)
                        }
                    }
                }
            }
            catch {
                TCSLogWithMark("could not get attributes from user")
            }
        }

    }
}

