//
//


/// Mechanism to create a local user and homefolder.
class XCredsLoginDone: XCredsBaseMechanism {

    override init(mechanism: UnsafePointer<MechanismRecord>) {
        super.init(mechanism: mechanism)

    }

    @objc override func run() {
        TCSLogWithMark("XCredsLoginDone mech starting")

        NotificationCenter.default.post(name: NSNotification.Name("hideProgress"), object: nil)
        allowLogin()

    }}
