//
//  WifiView.swift
import Cocoa
import CoreWLAN

class OKTabPopUpButton: NSPopUpButton {
  override var canBecomeKeyView: Bool {return true} //
}
@available(macOS, deprecated: 11)
class WifiWindowController: NSWindowController, NetworkManagerDelegate, NSMenuDelegate {
//    @IBOutlet weak var backgroundView: NonBleedingView!
//    @IBOutlet weak var mainView: NonBleedingView!
    @IBOutlet weak var certificateLabel: NSTextField!
    @IBOutlet weak var wifiCredentialTitleLabel: NSTextField?
    @IBOutlet weak var networkSearch: NSButton?
    @IBOutlet weak var networkPassword: NSSecureTextField?
    @IBOutlet weak var networkUsername: NSTextField?
    @IBOutlet weak var networkConnectButton: NSButton?
    @IBOutlet weak var networkstatusLabel: NSTextField?
    @IBOutlet weak var networkWifiPopup: NSPopUpButton?
//    @IBOutlet weak var networkOpenStatusLabel: NSTextField!
    @IBOutlet weak var certificatePopupButton: NSPopUpButton!
    @IBOutlet weak var networkPasswordLabel: NSTextField!
    //    @IBOutlet weak var dismissButton: NSButton!
    @IBOutlet var credentialsWindow: NSWindow!
    @IBOutlet weak var networkConnectionSpinner: NSProgressIndicator?
    @IBOutlet weak var addSSIDMenuButton: NSButton?
    @IBOutlet weak var addSSIDButton: NSButton?
    @IBOutlet weak var addSSIDText: NSTextField?
    @IBOutlet weak var addSSIDLabel: NSTextField?
    
    @IBOutlet weak var wifiSwitch: NSSwitch!
    @IBOutlet weak var networkUsernameLabel: NSTextField!
    @IBOutlet weak var wifiPopupMenu: NSMenu!
    @IBAction func help(_ sender: Any) {
    }

    @IBOutlet weak var networkUsernameView: NSView?
    @IBOutlet weak var networkPasswordView: NSView?

    var networks: Set<CWNetwork> = []
    var selectedNetwork:CWNetwork?
    let wifiLog = "wifiLog"
    private var defaultFadeDuration: TimeInterval = 0.1
    private var completionHandler: (() -> Void)?
    var delegate: XCredsMechanismProtocol?
    let networkManager = NetworkManager()

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
        certificatePopupButton.removeAllItems()
        certificatePopupButton.addItem(withTitle: "None")
        TCSLogWithMark("adding wifi networks")
        certificatePopupButton.addItems(withTitles: NetworkManager().identityCommonNames())


        networkManager.wifiState() { state in
            switch state {
            case .off:
                self.wifiSwitch.state = .off

            case .on:
                self.wifiSwitch.state = .on
            }
        }
    }


    @IBAction func menuItemSelected(_ popupButton: NSPopUpButton) {

        if popupButton.titleOfSelectedItem == networkManager.getCurrentSSID() {
            print("selected current");
        }
        else {
            if let network = popupButton.selectedItem?.representedObject as? CWNetwork {
                selectedNetwork = network
                configureUIForSelectedNetwork(network: network)
            }
        }



    }
    func menuNeedsUpdate(_ menu: NSMenu) {
        updateNetworks()
    }

    @objc func updateAvailableNetworks() {
        DispatchQueue.global().async {

            DispatchQueue.main.async {
                self.networkWifiPopup?.isEnabled=false
                self.networkConnectionSpinner?.startAnimation(true)
                self.networkConnectionSpinner?.isHidden=false

            }

            if let availableNetworks = self.networkManager.findNetworks() {
                self.networks=availableNetworks
            }
            DispatchQueue.main.async {
                self.networkWifiPopup?.isEnabled=true
                self.networkConnectionSpinner?.stopAnimation(self)
                self.networkConnectionSpinner?.isHidden=true
                self.updateNetworks()
            }
        }


    }

    func updateNetworks() {
        os_log("Remove allItems")
        self.networkWifiPopup?.removeAllItems()
        if networks.count == 0 {
            os_log("Unable to find any networks", log: wifiLog, type: .debug)
            self.networkWifiPopup?.addItem(withTitle: "No networks")
        }
        for network in networks {
            if let networkName = network.ssid {
                 self.networkWifiPopup?.addItem(withTitle: networkName)
                self.networkWifiPopup?.lastItem?.representedObject=network
                 self.networks.insert(network)
            }
        }

        self.networkWifiPopup?.selectItem(withTitle: networkManager.getCurrentSSID() ?? "")

        configCurrentNetwork()

    }
    func configCurrentNetwork() {
        TCSLogWithMark()
        if let currentNetworkName = networkManager.getCurrentSSID() {
             self.networkstatusLabel?.stringValue = "Connected to: \(currentNetworkName)"
        } else {
             self.networkstatusLabel?.stringValue = "Connected via Ethernet"
        }
        TCSLogWithMark()
    }

    private func configureAppearance() {
        TCSLogWithMark()
        self.networkWifiPopup?.removeAllItems()
        self.networkWifiPopup?.addItem(withTitle: "Choose Network...")
    }



    func set(completionHandler: (() -> Void)?) {
        self.completionHandler = completionHandler
    }

    @IBAction func dismissButton(_ sender: Any) {
        TCSLogWithMark("closing window")
        DispatchQueue.main.async {
            TCSLogWithMark("Triggering login window reload")
            self.delegate?.reload()
            self.window?.close()
        }
    }

    @IBAction func connect(_ sender: Any) {
        if let selectedNetwork = selectedNetwork {

            let userPassword = self.networkPassword?.stringValue
            let username = self.networkUsername?.stringValue
            var identity:SecIdentity?
            if certificatePopupButton.indexOfSelectedItem>0{
                let cn = certificatePopupButton.title
                TCSLogWithMark("using cert \(cn)")
                let identityFromCN = TCSKeychain.findIdentity(withSubject: cn)
                TCSLogWithMark("using cert2 \(identityFromCN.debugDescription)")

                identity = identityFromCN?.takeRetainedValue()
                TCSLogWithMark("using identity: \(cn)")
                TCSLogWithMark("identity: \(identity.debugDescription)")
            }
            TCSLogWithMark("connectWiFi")
            let connected = networkManager.connectWifi(with: selectedNetwork, password: userPassword, username: username, identity: identity)
            TCSLogWithMark("done connectWifi")

            if connected {
                TCSLogWithMark("connected")
                NSApp.stopModal()
                credentialsWindow.orderOut(self)

                networkManager.delegate = self
                networkManager.internetConnected()
                return
            } else {
                TCSLogWithMark("not connected")
                credentialsWindow.shake(self)
            }
        }
    }


    @IBAction func wifiButtonPressed(_ sender: NSSwitch) {

        if sender.state == .off {
            networkManager.setWiFiState(.off) {
                self.updateAvailableNetworks()



            }
        }
        else {
            networkManager.setWiFiState(.on) {
                self.networkWifiPopup?.isEnabled=false
                self.networkConnectionSpinner?.startAnimation(true)
                self.networkConnectionSpinner?.isHidden=false

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.updateAvailableNetworks()
                }
            }
        }
        TCSLogWithMark("Wifi Button Switch changed")


    }
    func configureUIForSelectedNetwork(network: CWNetwork) {
        self.networkUsername?.stringValue = ""
        self.networkPassword?.stringValue = ""
        let securityType = networkManager.networkSecurityType(network)

        switch securityType {
        case .none:
            connect(self)

            return
        case .password:
            self.networkUsername?.isHidden = true
            networkUsernameLabel.isHidden = true
            certificateLabel.isHidden = true
            self.certificatePopupButton.isHidden = true

            self.networkPassword?.isHidden = false
            networkPasswordLabel?.isHidden = false

        case .enterpriseUserPassword:
            self.networkUsername?.isHidden = false
            networkUsernameLabel.isHidden = false

            self.networkPassword?.isHidden = false
            networkPasswordLabel?.isHidden = false
            certificateLabel.isHidden = false
            self.certificatePopupButton.isHidden = false

        }
        wifiCredentialTitleLabel?.stringValue = "The wifi network \"\(network.ssid ?? "" )\" requires login:"
        credentialsWindow.canBecomeVisibleWithoutLogin = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.credentialsWindow.level = .screenSaver+10
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
        let results = networkManager.findNetworkWithSSID(ssid: addSSIDText?.stringValue ?? "Unknown SSID" ) ?? []
        
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



    // MARK: - NetworkManager Delegates
    func networkManagerFullyFinishedInternetConnectionTimer() {
//        self.enableUI()
        self.networkUsername?.stringValue = ""
        self.networkPassword?.stringValue = ""
    }

    func networkManagerConnectedToNetwork() {
        TCSLogWithMark("WiFi successfully connected leaving manager")
        self.dismissButton(self)
    }
}
