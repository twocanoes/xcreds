//
//  AppDelegate.swift
//  xCreds
//
//  Created by Timothy Perfitt on 4/5/22.
//

import Cocoa
import ArgumentParser
import CryptoKit

@main
struct xcreds:ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "Command line interface for XCreds.",
        subcommands: [ImportUsers.self, ImportUser.self, ShowUser.self,ShowUsers.self, UpdateAdminUser.self,ShowAdminUser.self, ClearAdminUser.self,ClearAllUsers.self, RunApp.self],
        defaultSubcommand: RunApp.self)

}

extension xcreds {
    struct RunApp:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Start app normally.")
            @Argument(parsing: .allUnrecognized)
            var other: [String] = []

        func run() throws {

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
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }
            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            if let adminUser = try userManager.localAdminCredentials(), !adminUser.username.isEmpty {
                print("\(adminUser.username)")
            }
            else {
                print("admin user not set")
            }

        }
    }
}
extension xcreds {
    struct ClearAllUsers:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Clear all users. Does not clear the admin user.")

        func run() throws {
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
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }

            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            try userManager.updateLocalAdminCredentials(user: SecretKeeperUser(fullName: "", username: "", password: "", uid: -1, rfidUID: Data()))

        }
    }
}
extension xcreds {
    struct UpdateAdminUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Set the current admin user used for resetting keychain.")

        @Option(help: "Update Admin username")
        var adminusername:String

        @Option(help: "Update Admin password")
        var adminpassword:String

        func run() throws {
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)
            }

            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)
            try userManager.updateLocalAdminCredentials(user: SecretKeeperUser(fullName: "", username: adminusername, password: adminpassword, uid: NSNumber(value: -1), rfidUID: Data()))
        }

    }
}
extension xcreds {
    struct ImportUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Import an RFID user.")

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

        func run() throws {
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }

            do {
                if !username.isEmpty && !password.isEmpty && !fullname.isEmpty && !rfiduid.isEmpty{


                    let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")

                    let userManager = UserSecretManager(secretKeeper: secretKeeper)
                    guard let rfidUIDData = Data(fromHexEncodedString: rfiduid) else {
                        print("invalid rfid. Must be hex with no 0x in front")
                        return

                    }


                    try userManager.updateUIDUser(fullName: fullname, rfidUID: rfidUIDData, username: username, password: password, uid: NSNumber(value: Int(uid) ?? -1))

                }
            }
            catch {
                print(error.localizedDescription)

            }
        }

    }
}
extension xcreds {
    struct ShowUsers:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show RFID users.")


        func run() throws {
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }


            do {

                let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
                let userManager = UserSecretManager(secretKeeper: secretKeeper)
                let users = try userManager.uidUsers()



                print("RFID UID:Full Name:Username:UserID")

                guard let rfidUsers = users.userDict else {
                    return

                }
                for currKey in rfidUsers.keys{
                    if let user = rfidUsers[currKey], let fullname = user.fullName,let passwordData = rfidUsers[currKey]?.password {
//                        print(passwordData)
//                        PasswordCryptor().aesDecrypt(encryptedData: passwordData, uid: uid)
                        print("\(currKey):\(fullname):\(user.username):\(user.uid)")

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
    struct ShowUser:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Show RFID user.")


        @Option(help: "RFID-uid in hex with no 0x in front.")
        var rfidUIDString:String


        func run() throws {
            if geteuid() != 0  {
                print("This operation requires root. Please run with sudo.")
                NSApplication.shared.terminate(self)

            }


            do {

                let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
                let userManager = UserSecretManager(secretKeeper: secretKeeper)
                let users = try userManager.uidUsers()


                guard let rfidUsers = users.userDict else {
                    return

                }
                let rfidUidData = Data(fromHexEncodedString: rfidUIDString)
                guard let rfidUidData = rfidUidData else {
                    print("bad RFID rfidUidData")

                    return
                }
                let hashedUID=Data(SHA256.hash(data: rfidUidData))

                let user = rfidUsers[hashedUID]
                guard let passwordData = user?.password else {
                    print("could not find user.")

                    return

                }
                let password = try PasswordCryptor().aesDecrypt(encryptedData: passwordData, uid: rfidUidData)


                if password.count>0 {
                    print("password set")
                }

            }
            catch {
                print(error.localizedDescription)
            }


        }
    }
}




extension xcreds {
    struct ImportUsers:ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Import users from a CSV for RFID login. Format:Full Name,Username,Password,UID,RFID-UID. All imported user data is encrypted with a ECC stored in the system keychain and the encrypted data is stored in a file located in /usr/local/var/twocanoes. The file is only readable by root.")


        @Option(help: "infilepath")
        var infilepath:String

        func run() throws {

            if !infilepath.isEmpty {

                if FileManager.default.fileExists(atPath: infilepath)==false {

                    print("\(infilepath) does not exist.")

                }

                do {
                    let contentsOfFile = try String(contentsOfFile: infilepath, encoding: .windowsCP1250)

                    let rfidUsers=RFIDUsers(rfidUsers: [:])
                    let lineArray = contentsOfFile.components(separatedBy:"\n")

                    let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")

                    let userManager = UserSecretManager(secretKeeper: secretKeeper)

                    for line in lineArray {

                        let userInfo = line.components(separatedBy: ",")
                        if userInfo.count != 5 {
                            print("invalid line. skippinng. \(line)")

                        }
                        let fullname = userInfo[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let username = userInfo[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let password = userInfo[2].trimmingCharacters(in: .whitespacesAndNewlines)
                        let uid = Int(userInfo[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
                        let rfidUid = userInfo[4].trimmingCharacters(in: .whitespacesAndNewlines)
                        print("importing \(rfidUid):\(fullname):\(username):\(uid)")


                        guard let rfidUidData = Data(fromHexEncodedString: rfidUid) else {

                            print("invalid uid")
                            return
                        }
                        let hashedUID=Data(SHA256.hash(data: rfidUidData))

                        rfidUsers.userDict?[hashedUID] = try SecretKeeperUser(fullName: fullname, username: username, password: password, uid: NSNumber(value: Int(uid)), rfidUID: rfidUidData)
                    }

                    try userManager.setUIDUsers(rfidUsers)

                }
                catch {
                    print("\(infilepath) cannot be read. \(error)")

                }
            }

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
        mainController = MainController()
        mainController?.setup()

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

