//
//  WifiView.swift
import Cocoa
import CoreWLAN

class WifiWindowController: NSWindowController, WifiManagerDelegate, NSMenuDelegate {
//    @IBOutlet weak var backgroundView: NonBleedingView!
//    @IBOutlet weak var mainView: NonBleedingView!
    @IBOutlet weak var wifiCredentialTitleLabel: NSTextField?
    @IBOutlet weak var networkSearch: NSButton?
    @IBOutlet weak var networkPassword: NSSecureTextField?
    @IBOutlet weak var networkUsername: NSTextField?
    @IBOutlet weak var networkConnectButton: NSButton?
    @IBOutlet weak var networkstatusLabel: NSTextField?
    @IBOutlet weak var networkWifiPopup: NSPopUpButton?
//    @IBOutlet weak var networkOpenStatusLabel: NSTextField!
    @IBOutlet weak var networkPasswordLabel: NSTextField!
    //    @IBOutlet weak var dismissButton: NSButton!
    @IBOutlet var credentialsWindow: NSWindow!
    @IBOutlet weak var networkConnectionSpinner: NSProgressIndicator?
    @IBOutlet weak var addSSIDMenuButton: NSButton?
    @IBOutlet weak var addSSIDButton: NSButton?
    @IBOutlet weak var addSSIDText: NSTextField?
    @IBOutlet weak var addSSIDLabel: NSTextField?
    
    @IBOutlet weak var networkUsernameLabel: NSTextField!
    @IBOutlet weak var wifiPopupMenu: NSMenu!
    @IBAction func help(_ sender: Any) {
         TCSLogWithMark()
    }

    @IBOutlet weak var networkUsernameView: NSView?
    @IBOutlet weak var networkPasswordView: NSView?

    var networks: Set<CWNetwork> = []
    var selectedNetwork:CWNetwork?
    let wifiLog = "wifiLog"
    private var defaultFadeDuration: TimeInterval = 0.1
    private var completionHandler: (() -> Void)?
    let wifiManager = WifiManager()

    @IBAction func wifiCredentialCancelButtonPressed(_ sender: NSButton) {
        NSApp.stopModal()
        credentialsWindow.orderOut(self)
        updateNetworks()

    }
    override func awakeFromNib() {
        TCSLogWithMark()
        super.awakeFromNib()
        TCSLogWithMark()

        configureAppearance()
        TCSLogWithMark()
        updateAvailableNetworks()
        self.networkUsernameView?.isHidden=true
        self.networkPasswordView?.isHidden=true

//        networkSearch.performClick(nil)
//        TCSLogWithMark()
//
//        networkSearch.becomeFirstResponder()
//        TCSLogWithMark()
//
//
//        networkWifiPopup.action = #selector(networkWifiPopupChangedValue)
//        TCSLogWithMark()
//
//        networkWifiPopup.target = self
//        TCSLogWithMark()
//
//        perform(#selector(connectNetwork), with: nil, afterDelay: 0.05)
//        TCSLogWithMark()
//
//        self.networkConnectionSpinner.isHidden = true
//        TCSLogWithMark()

    }


    @IBAction func menuItemSelected(_ popupButton: NSPopUpButton) {

        if popupButton.titleOfSelectedItem == wifiManager.getCurrentSSID() {
            print("selected current");
        }
        else {
//            configureUIForSelectedNetwork()
            if let network = popupButton.selectedItem?.representedObject as? CWNetwork {
                selectedNetwork = network
                configureUIForSelectedNetwork(network: network)
            }
        }



    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        updateNetworks()
    }
//    override func resizeSubviews(withOldSize oldSize: NSSize) {
//        super.resizeSubviews(withOldSize: oldSize)
//        if !(getManagedPreference(key: .LoginScreen) as? Bool ?? false) {
//            fadeInBackgroundView()
//        }
//    }


    @objc func updateAvailableNetworks() {
        DispatchQueue.global().async {

            DispatchQueue.main.async {
                self.networkWifiPopup?.isEnabled=false
                self.networkConnectionSpinner?.startAnimation(true)
                self.networkConnectionSpinner?.isHidden=false

            }

            if let availableNetworks = self.wifiManager.findNetworks() {
                self.networks=availableNetworks
            }
            DispatchQueue.main.async {
                self.networkWifiPopup?.isEnabled=true
                self.networkConnectionSpinner?.stopAnimation(self)
                self.networkConnectionSpinner?.isHidden=true
                self.updateNetworks()

            }
        }

//        guard  networks != nil else {
//            os_log("Unable to find any networks", log: wifiLog, type: .debug)
//            self.networkWifiPopup?.addItem(withTitle: "No networks")
//            return
//        }


    }


    func updateNetworks() {
        os_log("Remove allItems")
        self.networkWifiPopup?.removeAllItems()
        TCSLogWithMark()

        TCSLogWithMark()

        if networks.count == 0 {
            os_log("Unable to find any networks", log: wifiLog, type: .debug)
            self.networkWifiPopup?.addItem(withTitle: "No networks")
        }
        TCSLogWithMark()

        for network in networks {
            if let networkName = network.ssid {
                 self.networkWifiPopup?.addItem(withTitle: networkName)
                self.networkWifiPopup?.lastItem?.representedObject=network
                 self.networks.insert(network)
            }
        }
        TCSLogWithMark()

        self.networkWifiPopup?.selectItem(withTitle: wifiManager.getCurrentSSID() ?? "")
        TCSLogWithMark()

        configCurrentNetwork()
        TCSLogWithMark()

//        configureUIForSelectedNetwork()
        TCSLogWithMark()


    }
    func configCurrentNetwork() {
        TCSLogWithMark()
        if let currentNetworkName = wifiManager.getCurrentSSID() {
             self.networkstatusLabel?.stringValue = "Connected to: \(currentNetworkName)"
        } else {
             self.networkstatusLabel?.stringValue = "Connected via Ethernet"
        }
        TCSLogWithMark()
    }

    private func configureAppearance() {
        TCSLogWithMark()
        self.networkWifiPopup?.removeAllItems()
        TCSLogWithMark()
        self.networkWifiPopup?.addItem(withTitle: "Choose Network...")
        TCSLogWithMark()
//        self.networkOpenStatusLabel.stringValue = "Open WiFi Networks are not supported. Find and join a secure Network to continue."
        TCSLogWithMark()
//        mainView.wantsLayer = true
//        TCSLogWithMark()
//        mainView.layer?.backgroundColor = NSColor.white.cgColor
//        TCSLogWithMark()
//        mainView.layer?.cornerRadius = 5
//        TCSLogWithMark()
//        mainView.alphaValue = 1
//        TCSLogWithMark()
//
//        backgroundView.wantsLayer = true
//        TCSLogWithMark()
//        backgroundView.layer?.backgroundColor = NSColor.lightGray.cgColor
//        TCSLogWithMark()
//        backgroundView.alphaValue = 0
//        TCSLogWithMark()
    }



    func set(completionHandler: (() -> Void)?) {
        self.completionHandler = completionHandler
    }

    @IBAction func dismissButton(_ sender: Any) {
        self.window?.close()
//        NSAnimationContext.beginGrouping()
//        NSAnimationContext.current.duration = defaultFadeDuration
////        animator().removeFromSuperview()
//        NSAnimationContext.endGrouping()
//        completionHandler?()
    }

    @IBAction func connect(_ sender: Any) {
//        self.disableUI()
//        for network in networks {
//            if let networkName = network.ssid {
//                if (networkName == self.networkWifiPopup?.selectedItem?.title) {
        if let selectedNetwork = selectedNetwork {


                    let userPassword = self.networkPassword?.stringValue
                    let username = self.networkUsername?.stringValue

                    let connected = wifiManager.connectWifi(with: selectedNetwork, password: userPassword, username: username)
                    if connected {
//                        self.networkstatusLabel?.stringValue = "Connected to: \(networkName)"
                        NSApp.stopModal()
                        credentialsWindow.orderOut(self)

                        wifiManager.delegate = self
                        wifiManager.internetConnected()
                        return
                    } else {
//                        self.networkstatusLabel?.stringValue = "No Internet Connection"
//                        self.enableUI()
                        credentialsWindow.shake(self)
                    }
                }
//            }
//        }
    }


    func configureUIForSelectedNetwork(network: CWNetwork) {
        self.networkUsername?.stringValue = ""
        self.networkPassword?.stringValue = ""
        let securityType = wifiManager.networkSecurityType(network)

        switch securityType {
        case .none:
            let alert = NSAlert()

            alert.messageText = "Open WiFi Networks are not supported. Find and join a secure network to continue."
            alert.window.canBecomeVisibleWithoutLogin = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.modalWindow?.level = .screenSaver + 2
            }

            alert.runModal()
            updateNetworks()

            return
//            networkUsername?.isHidden = true
//            networkUsernameLabel.isHidden = true
//
//            networkPassword?.isHidden = true
//            networkPasswordLabel?.isHidden = true
        case .password:
            self.networkUsername?.isHidden = true
            networkUsernameLabel.isHidden = true

            self.networkPassword?.isHidden = false
            networkPasswordLabel?.isHidden = false

        case .enterpriseUserPassword:
            self.networkUsername?.isHidden = false
            networkUsernameLabel.isHidden = false

            self.networkPassword?.isHidden = false
            networkPasswordLabel?.isHidden = false

        }
        wifiCredentialTitleLabel?.stringValue = "The wifi network \"\(network.ssid ?? "" )\" requires login:"
        credentialsWindow.canBecomeVisibleWithoutLogin = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.credentialsWindow.level = .screenSaver+2
        }
        NSApp.runModal(for: credentialsWindow)

    }

    @IBAction func searchButton(_ sender: Any) {
        self.updateAvailableNetworks()
    }
    
    @IBAction func addSSIDMenuButton(_ sender: Any){
        // Hiding the other UI
        networkUsernameView?.isHidden = true
        networkPasswordView?.isHidden = true
        
        // Making the add SSID options appear
        addSSIDText?.isHidden = false
        addSSIDLabel?.isHidden = false
        addSSIDButton?.isHidden = false
    }
    
    @IBAction func addSSIDButton(_ sender: Any){
        
        // Searching for a WiFi of that name
        let results = wifiManager.findNetworkWithSSID(ssid: addSSIDText?.stringValue ?? "Unknown SSID" ) ?? []
        
        // Adding the SSID to the network list
        for network in results {
            self.networkWifiPopup?.addItem(withTitle: network.ssid ?? "Unknown SSID")
            self.networkWifiPopup?.selectItem(withTitle: network.ssid ?? "Unknown SSID")
        }
        networks.formUnion(results)
        
        // Making the other views accessible again
        networkUsernameView?.isHidden = false
        networkPasswordView?.isHidden = false
        
        // Hiding the add SSID options
        addSSIDText?.isHidden = true
        addSSIDLabel?.isHidden = true
        addSSIDButton?.isHidden = true
        
        // Updating the network changed UI
//        self.configureUIForSelectedNetwork()
    }

    // In order to prevent a NSView from bleeding it's mouse events to the parent, one must implement the empty methods.

//    func disableUI() {
//        DispatchQueue.main.async {
//            self.networkSearch?.isEnabled = false
//            self.networkWifiPopup?.isEnabled = false
//            self.networkUsername?.isEnabled = false
//            self.networkPassword?.isEnabled = false
//            self.networkConnectButton?.isEnabled = false
//            self.networkConnectionSpinner?.isHidden = false
//            self.networkConnectionSpinner?.startAnimation(self)
//        }
//    }
//
//    func enableUI() {
//        DispatchQueue.main.async {
//            self.networkSearch?.isEnabled = true
//            self.networkWifiPopup?.isEnabled = true
//            self.networkUsername?.isEnabled = true
//            self.networkPassword?.isEnabled = true
//            self.networkConnectButton?.isEnabled = true
//            self.networkConnectionSpinner?.isHidden = true
//            self.networkConnectionSpinner?.stopAnimation(self)
//        }
//    }

    // MARK: - WifiManager Delegates
    func wifiManagerFullyFinishedInternetConnectionTimer() {
//        self.enableUI()
        self.networkUsername?.stringValue = ""
        self.networkPassword?.stringValue = ""
    }

    func wifiManagerConnectedToNetwork() {
        self.dismissButton(self)
    }
}
