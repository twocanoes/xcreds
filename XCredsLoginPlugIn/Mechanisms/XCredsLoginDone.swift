//
//


/// Mechanism to create a local user and homefolder.
class XCredsLoginDone: XCredsBaseMechanism {

    override init(mechanism: UnsafePointer<MechanismRecord>) {
        super.init(mechanism: mechanism)

    }

    @objc override func run() {
        TCSLogWithMark("trying hide progress")

        NotificationCenter.default.post(name: NSNotification.Name("hideProgress"), object: nil)
        allowLogin()

    }}
