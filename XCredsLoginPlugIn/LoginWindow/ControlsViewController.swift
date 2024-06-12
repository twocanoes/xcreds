//
//  LoginWindowControlsWindowController.swift
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/3/22.
//

import Cocoa

class ControlsViewController: NSViewController, NSPopoverDelegate {
    @IBOutlet var systemInfoPopover: NSPopover!
    @IBOutlet var systemInfoPopoverViewController: NSViewController!
    var delegate: XCredsMechanismProtocol?

    @IBOutlet weak var buttonGridView: NSGridView!
    @IBOutlet weak var refreshGridColumn: NSGridColumn?
    @IBOutlet weak var shutdownGridColumn: NSGridColumn?
    @IBOutlet weak var restartGridColumn: NSGridColumn?

    @IBOutlet weak var systemInfoButton: NSButton!
    @IBOutlet weak var macLoginWindowGridColumn: NSGridColumn?
    @IBOutlet weak var wifiGridColumn: NSGridColumn?

    @IBOutlet weak var toolsView: NSView?

    let uiLog = "uiLog"
    @IBOutlet weak var versionTextField: NSTextField?
    @IBOutlet weak var systemInfoTextField: NSTextField?

    var loadPageURL:URL?
//    var resolutionObserver:Any?
    var wifiWindowController:WifiWindowController?
    @IBOutlet weak var trialVersionStatusTextField: NSTextField!
    var refreshTimer:Timer?
    var commandKeyDown = false
    var optionKeyDown = false
    var controlKeyDown = false
    var keyCodesPressed:[UInt16:Bool]=[:]
//    func dismiss() {
////        if let resolutionObserver = resolutionObserver {
////            NotificationCenter.default.removeObserver(resolutionObserver)
////        }
////        self.window?.close()
//    }
//    @objc override var windowNibName: NSNib.Name {
//        return NSNib.Name("ControlsViewController")
//    }

    static func initFromPlugin() -> ControlsViewController?{

        let bundle = Bundle.findBundleWithName(name: "XCreds")

        guard let bundle = bundle else {
            return nil
        }
        let controlsViewController = ControlsViewController.init(nibName: NSNib.Name("ControlsViewController"), bundle: bundle)
        return controlsViewController

    }


    func commandKey(evt: NSEvent) -> NSEvent{

        let flags = evt.modifierFlags.rawValue & NSEvent.ModifierFlags.command.rawValue
        if flags != 0 { //key code for command is 55
            commandKeyDown = true
        }
        else {
            commandKeyDown=false

        }

        let optionKeyFlags = evt.modifierFlags.rawValue & NSEvent.ModifierFlags.option.rawValue

        if optionKeyFlags != 0 {
            optionKeyDown=true
        }
        else {
            optionKeyDown=false
        }

        let controlKeyFlags = evt.modifierFlags.rawValue & NSEvent.ModifierFlags.control.rawValue

        if controlKeyFlags != 0 {
            controlKeyDown=true
        }
        else {
            controlKeyDown=false
        }
        return evt
    }

    func keyUp(key: NSEvent) -> NSEvent?{
        keyCodesPressed.removeValue(forKey: key.keyCode)
        return key
    }
    @IBAction func showSystemInfoButtonPressed(_ sender: NSButton) {
        if systemInfoPopover.isShown==true {
            systemInfoPopover.performClose(self)
            return
        }
        
        var sysInfo = SystemInfoHelper().info().joined(separator: "\n")

        if let prefDomainName=getManagedPreference(key: .ADDomain) as? String{

            let adSession = NoMADSession(domain:prefDomainName , user: "")
            let ldapServers = adSession.getSRVRecords(prefDomainName)

            if ldapServers.count>0{
                sysInfo.append("\nAD Domain:\(prefDomainName) (Reachable)\n")
            }
            else {
                sysInfo.append("\nAD Domain: \(prefDomainName) (Not Reachable)\n")
            }

        }
        self.systemInfoTextField?.stringValue = sysInfo
        self.systemInfoPopover.delegate=self
        systemInfoPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }
    func keyDown(key: NSEvent) -> NSEvent?{
        keyCodesPressed[key.keyCode]=true

        if (keyCodesPressed[76]==true || keyCodesPressed[36]==true) && (controlKeyDown==true && optionKeyDown==true) {
            guard let delegate = delegate else {
                TCSLogWithMark("No delegate set for restart")

                return key
            }

            let allowCombo = DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldAllowKeyComboForMacLoginWindow.rawValue)
            if allowCombo == true {
                keyCodesPressed.removeAll()
                if commandKeyDown == false {
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchLoginWindow"), object: self)


                }
                else {
                    delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.standardLoginWindow.rawValue)
                    delegate.allowLogin()

                }
                return nil
            }

        }
        return key
    }
    func setupSystemInfoButton() {
        let systemInfoButtonTitle = DefaultsOverride.standardOverride.string(forKey: PrefKeys.systemInfoButtonTitle.rawValue)

        switch systemInfoButtonTitle {
        case ".os":
            systemInfoButton.title = "macOS " + ProcessInfo.processInfo.operatingSystemVersionString

        case ".hostname":
            systemInfoButton.title = "Hostname: " + ProcessInfo.processInfo.hostName
        case ".ipaddress":
            systemInfoButton.title = "IP Address: " + (SystemInfoHelper().ipAddress() ?? "No IPAddress")

        case ".serial":
            systemInfoButton.title = "Serial: " + getSerial()

        case ".mac":
            systemInfoButton.title = "MAC Address:" + getMAC()

        case ".computername":
            systemInfoButton.title = "Computer Name:" +  (Host.current().localizedName ?? "unknown computername")

        case ".ssid":
            systemInfoButton.title="SSID: " + (WifiManager().getCurrentSSID() ?? "no SSID")

        default:
            if let systemInfoButtonTitle = systemInfoButtonTitle, systemInfoButtonTitle.count<21 {
                systemInfoButton.title = systemInfoButtonTitle
            }
        }
    }
    override func awakeFromNib() {
        TCSLogWithMark()
        super.awakeFromNib()
        let licenseState = LicenseChecker().currentLicenseState()
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: commandKey(evt:))
        self.trialVersionStatusTextField?.isHidden = false
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: keyDown(key:))
        NSEvent.addLocalMonitorForEvents(matching: .keyUp, handler: keyUp(key:))

        setupSystemInfoButton()
        switch licenseState {

        case .valid:
            TCSLogWithMark("valid license")
            self.trialVersionStatusTextField?.isHidden = true

        case .expired:
            self.trialVersionStatusTextField?.isHidden = false
            self.trialVersionStatusTextField.stringValue = "License Expired. Please visit twocanoes.com for more information."


        case .trial(let daysRemaining):
            TCSLogWithMark("Trial")
            self.trialVersionStatusTextField?.isHidden = false
            if daysRemaining==1 {
                self.trialVersionStatusTextField.stringValue = "XCreds Trial. One day remaining."

            }
            else {
                self.trialVersionStatusTextField.stringValue = "XCreds Trial. \(daysRemaining) days remaining."
            }

        case .trialExpired:
            TCSLogErrorWithMark("Trial Expired")
            self.trialVersionStatusTextField?.isHidden = false
            self.trialVersionStatusTextField.stringValue = "Trial Expired"



        default:
            TCSLogErrorWithMark("invalid license")
            self.trialVersionStatusTextField?.isHidden = false
            self.trialVersionStatusTextField.stringValue = "Invalid License. Please visit twocanoes.com for more information."

        }
        TCSLogWithMark()
        setupLoginWindowControlsAppearance()
        versionTextField?.stringValue = ""

        let bundle = Bundle.findBundleWithName(name: "XCreds")

        if let bundle = bundle {

            let infoPlist = bundle.infoDictionary
            if let infoPlist = infoPlist,
               let verString = infoPlist["CFBundleShortVersionString"],
               let buildString = infoPlist["CFBundleVersion"]
            {
                versionTextField?.stringValue = "XCreds \(verString) (\(buildString))"

            }
        }
//        resolutionObserver = NotificationCenter.default.addObserver(forName:NSApplication.didChangeScreenParametersNotification, object: nil, queue: nil) { notification in
//            TCSLogWithMark("Resolution changed. Resetting size")
//            self.setupLoginWindowControlsAppearance()
//
//
//        }

        let refreshTimerSecs = DefaultsOverride.standardOverride.integer(forKey: PrefKeys.autoRefreshLoginTimer.rawValue)

        if refreshTimerSecs > 0 {
            TCSLogWithMark("Setting refresh timer")

        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshTimerSecs), repeats: true, block: { [self] timer in
                TCSLogWithMark("refreshing in timer")
                delegate?.reload()
            })
        }
    }
    fileprivate func setupLoginWindowControlsAppearance() {
        TCSLogWithMark()
        DispatchQueue.main.async {
            self.view.wantsLayer=true
            self.view.layer?.backgroundColor = CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.4)


            TCSLogWithMark()

            self.wifiGridColumn?.isHidden = !DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowConfigureWifiButton.rawValue)

            self.shutdownGridColumn?.isHidden = !DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowShutdownButton.rawValue)


            self.restartGridColumn?.isHidden = !DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowRestartButton.rawValue)


            self.systemInfoButton?.isHidden = !DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowSystemInfoButton.rawValue)


            TCSLogWithMark()

            self.macLoginWindowGridColumn?.isHidden = !DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowMacLoginButton.rawValue)
            TCSLogWithMark()

            self.versionTextField?.isHidden = !DefaultsOverride.standardOverride.bool(forKey: PrefKeys.shouldShowVersionInfo.rawValue)

            TCSLogWithMark()

//            self.window?.level = .normal+1
            TCSLogWithMark("ordering controls front")
//            self.window?.orderFrontRegardless()

//            self.window?.titlebarAppearsTransparent = true
//            self.window?.isMovable = false
//            self.window?.canBecomeVisibleWithoutLogin = true
            TCSLogWithMark()
//
//            let screenRect = NSScreen.screens[0].frame
//            let windowRec = NSMakeRect(0, 0, screenRect.width,109)
//            self.frame=windowRec


//            TCSLogWithMark("screens: \(NSScreen.screens) height is \(windowRec), secreenredc is \(screenRect)")
            TCSLogWithMark()

//            self.window?.setFrame(windowRec, display: true, animate: false)
//            self.window?.viewsNeedDisplay=true
//            TCSLogWithMark("height is \(String(describing: self.window?.frame))")
        }

    }
    @IBAction func showNetworkConnection(_ sender: Any) {
//        username.isHidden = true
        TCSLogWithMark()

        wifiWindowController = WifiWindowController(windowNibName: NSNib.Name("WifiWindowController"))
        TCSLogWithMark()

        guard let windowController = wifiWindowController, let window = windowController.window else {
            TCSLogWithMark("no window for wifi")
            return
        }
        windowController.delegate=self.delegate
        TCSLogWithMark("setting window level")
//        let colorValue=0.9
//        let alpha=0.95
//        window.backgroundColor=NSColor(deviceRed: colorValue, green: colorValue, blue: colorValue, alpha: alpha)
        if let level = self.view.window?.level {
            window.level = level+1
        }

        TCSLogWithMark("wifiWindowController ordering controls front")
        window.orderFrontRegardless()
        TCSLogWithMark()
//        window.titlebarAppearsTransparent = true
        window.isMovable = true
        window.canBecomeVisibleWithoutLogin = true
        window.makeKeyAndOrderFront(self)

//        window.titlebarAppearsTransparent = true


        let screenRect = NSScreen.screens[0].frame
        window.setFrame(screenRect, display: true, animate: false)


        TCSLogWithMark()
//        guard let wifiWindowController = WifiWindowViewController.createFr.createFromNib(in: .mainLogin) else {
//            os_log("Error showing network selection.", log: uiLog, type: .debug)
//            return
//        }
//
        
//        wifiView.frame = windowContentView.frame
//        let completion = {
//            os_log("Finished working with wireless networks", log: self.uiLog, type: .debug)
////            self.username.isHidden = false
////            self.username.becomeFirstResponder()
//        }
//        wifiView.set(completionHandler: completion)
//        windowContentView.addSubview(wifiView)
    }

    @IBAction func refreshButtonPressed(_ sender: Any) {
        TCSLogWithMark("refreshButtonPressed")
        DefaultsOverride.standardOverride.refreshCachedPrefs()

        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for refresh")
            return
        }
        TCSLogWithMark("refreshing")

        delegate.reload()

    }

    @IBAction func restartClick(_ sender: Any) {
        TCSLogWithMark("Setting restart user")
        guard let delegate = delegate else {
            TCSLogWithMark("No delegate set for restart")

            return
        }
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.restart.rawValue)

        delegate.allowLogin()
    }

    @IBAction func shutdownClick(_ sender: Any) {
        TCSLogWithMark("Setting shutdown user")
        guard let delegate = delegate else {
            TCSLogErrorWithMark("No delegate set for shutdown")
            return
        }
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.shutdown.rawValue)
        TCSLogWithMark("calling allowLogin")

        delegate.allowLogin()
    }
    @IBAction func resetToStandardLoginWindow(_ sender: Any) {
        TCSLogWithMark("switch login window")
        if commandKeyDown == false {

            NotificationCenter.default.post(name: NSNotification.Name("SwitchLoginWindow"), object: self)
            return
        }

        guard let delegate = delegate else {
            TCSLogErrorWithMark("No delegate set for resetToStandardLoginWindow")
            return
        }
        delegate.setContextString(type: kAuthorizationEnvironmentUsername, value: SpecialUsers.standardLoginWindow.rawValue)

        delegate.allowLogin()
    }



}


