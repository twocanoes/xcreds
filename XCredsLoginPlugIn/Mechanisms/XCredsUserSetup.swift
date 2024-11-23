//
//  XCredsUserSetup.swift
//
//

class XCredsUserSetup: XCredsBaseMechanism {

    @objc override func run() {
        TCSLogWithMark("XCredsUserSetup mech starting")
        do {


            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)

            let users = try userManager.uidUsers()

            self.setHint(type: .secureUsers, hint: users as NSSecureCoding)

        }
        catch {
            TCSLogWithMark(error.localizedDescription)
        }
        let _ = allowLogin()


    }
}
