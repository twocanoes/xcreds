//
//  NetworkManager.swift
//

import Foundation
import CoreWLAN
import Cocoa
import SystemConfiguration
import Network

enum SecurityType {
    case none // show without additional fields
    case password // show password field
    case enterpriseUserPassword //show user and password
}

enum WiFiPowerState:String {
    case off = "off"
    case on = "on"
}
@objc protocol NetworkManagerDelegate: AnyObject {
    func networkManagerFullyFinishedInternetConnectionTimer()
    @objc optional func networkManagerConnectedToNetwork()
}
@available(macOS, deprecated: 11)
class NetworkManager: CWEventDelegate {
    private var error: Error?
    private var currentInterface: CWInterface?

    var timer: Timer?
    weak var delegate: NetworkManagerDelegate?
    var monitor:NWPathMonitor?
    var task:TCTaskWrapperWithBlocks?
    init() {
        let defaultInterface = CWWiFiClient.shared().interface()
//        CWWiFiClient.shared().delegate = self

//        do {
//            try CWWiFiClient.shared().startMonitoringEvent(with: .ssidDidChange)
//        } catch {
//            self.error = error
//        }

        let name = defaultInterface?.interfaceName
        if defaultInterface != nil && name != nil {
            currentInterface = defaultInterface
        } else {
            let names = CWWiFiClient.interfaceNames()
            if (names?.count ?? 0) >= 1 && names?.contains("en1") ?? false {
                currentInterface = CWWiFiClient.shared().interface(withName: "en1")
            }
        }

    }
    func wifiState(completion:@escaping(WiFiPowerState)->Void) {
        let interface = wifiInterface()

        var output:String = ""
        var errOutput = ""
        task = TCTaskWrapperWithBlocks(start: {

        }, end: {

            if output.contains("On") {
                completion(.on)
            }
            else {
                completion(.off)

            }
        }, outputBlock: { outputMsg in
            if let outputMsg = outputMsg {
                output += outputMsg
            }
        }, errorOutputBlock: { outputErr in
            if let outputErr = outputErr {
                errOutput += outputErr
            }
        }, arguments: ["/usr/sbin/networksetup","-getairportpower", interface])
        task?.startProcess()


    }

    func setWiFiState(_ powerState:WiFiPowerState,completion:@escaping()->Void)  {

        let interface = wifiInterface()

        task = TCTaskWrapperWithBlocks(start: {

        }, end: {
            completion()
        }, outputBlock: { outputMsg in
            TCSLogWithMark(outputMsg ?? "")
        }, errorOutputBlock: { outputErr in
            TCSLogWithMark(outputErr ?? "")
        }, arguments: ["/usr/sbin/networksetup","-setairportpower", interface,powerState.rawValue])
        task?.startProcess()

    }
    func wifiInterface() -> String {
        let names = CWWiFiClient.interfaceNames()

        if names?.contains("en0") != nil {
            return "en0"
        }
        else {
            return "en1"
        }
    }
    func getCurrentSSID() -> String? {
        TCSLogWithMark()
        return currentInterface?.ssid()
    }

    func identityCommonNames()->Array<String>{

        var returnCommonNames=Array<String>()
        let availableIdentityInfo =  TCSKeychain.availableIdentityInfo() as? Array <Dictionary<String,String>>
        if let availableIdentityInfo = availableIdentityInfo {

            for ident in availableIdentityInfo{

                if let cn = ident["cn"] {
                    returnCommonNames.append(cn)
                    TCSLogWithMark(cn)
                }
            }
        }
        return returnCommonNames

    }
    func findNetworks() -> Set<CWNetwork>? {
        var result: Set<CWNetwork> = []
        do {
            result = try currentInterface?.scanForNetworks(withSSID: nil) ?? []
        } catch let err {
            self.error = err
            return nil
        }
        return result
    }
    func findNetworkWithSSID(ssid: String) -> Set<CWNetwork>? {
        var result: Set<CWNetwork> = []
        do {
            result = try currentInterface?.scanForNetworks(withName: ssid) ?? []
        } catch let err {
            self.error = err
            return nil
        }
        return result
    }

    func findNetworksToSSID() -> Set<String>? {

        guard let networks = findNetworks() else {
            return nil
        }

        var result: Set<String> = []
        for network in networks {
            guard let ssid = network.ssid else {
                continue
            }
            result.insert(ssid)
        }
        return result
    }

    func connectWifi(fromName name: String, password: String?, username: String?) -> Bool {
        if let cachedScanResults = currentInterface?.cachedScanResults() {
            for network in cachedScanResults {
                let searchName = network.ssid
                if (searchName == name) {
                    return connectWifi(with: network, password: password, username: username)
                }
            }
        }

        if let networks = findNetworks() {
            for network in networks {
                let searchName = network.ssid
                if (searchName == name) {
                    return connectWifi(with: network, password: password, username: username)
                }
            }
        }
        return false
    }

    func turnWiFiOff()  {


    }
    func connectWifi(with network: CWNetwork, password: String?, username: String?, identity: SecIdentity? = nil) -> Bool {
        var result = false

        for _ in 1...3 {
            do {
                TCSLogWithMark("connecting")
                currentInterface?.disassociate()

                if username != nil && username != "" {
                    TCSLogWithMark("connecting \(username ?? "<unknown username")")
                    try currentInterface?.associate(toEnterpriseNetwork: network, identity: identity, username: username, password: password)
                } else {
                    TCSLogWithMark("connecting with password only \(network)")
                    try currentInterface?.associate(to: network, password: password)
                    TCSLogWithMark("done associating")

                }
                result = true
                break
            } catch {
                TCSLogWithMark("caught error: \(error)")
                self.error = error
            } //do
        } //for
        return result
    }

    var currentNetworkName: String {
        return CWWiFiClient.shared().interface(withName: nil)?.ssid() ?? ""
    }

    /** Labels describing the IEEE 802.11 physical layer mode */
    let SecurityLabels: [CWSecurity: String] = [
        /** No authentication required */
        .none:               "None",               // 0
        /** WEP security */
            .WEP:                "WEP",                // 1
        /** WPA personal authentication */
            .wpaPersonal:        "WPAPersonal",        // 2
        /** WPA/WPA2 personal authentication */
            .wpaPersonalMixed:   "WPAPersonalMixed",   // 3
        /** WPA2 personal authentication */
            .wpa2Personal:       "WPA2Personal",       // 4
        .personal:           "Personal",           // 5
        /** Dynamic WEP security */
            .dynamicWEP:         "DynamicWEP",         // 6
        /** WPA enterprise authentication */
            .wpaEnterprise:      "WPAEnterprise",      // 7
        /** WPA/WPA2 enterprise authentication */
            .wpaEnterpriseMixed: "WPAEnterpriseMixed", // 8
        /** WPA2 enterprise authentication */
            .wpa2Enterprise:     "WPA2Enterprise",     // 9
        .enterprise:         "Enterprise",         // 10
        /** Unknown security type */
            .unknown:            "Unknown",            // Int.max
    ]

    func networkSecurityType(_ network: CWNetwork) -> SecurityType {
        for securityLabel in SecurityLabels {
            if network.supportsSecurity(securityLabel.key) {
                if(securityLabel.key == .none) {
                    return .none
                } else if securityLabel.key == .enterprise || securityLabel.key == .wpaEnterprise
                            || securityLabel.key == .wpa2Enterprise || securityLabel.key == .wpaEnterpriseMixed {
                    return .enterpriseUserPassword
                } else {
                    return .password
                }
            }
        }
        return .password
    }
    
    

    public func internetConnected() {
        TCSLogWithMark("turning on network monitor")
        configureNetworkMonitor()
        self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: { timer in
            TCSLogWithMark("cancelMonitor")

            self.monitor?.cancel()

        })
    }

    func configureNetworkMonitor(){
        
        self.monitor = NWPathMonitor()

        monitor?.pathUpdateHandler = { path in
            TCSLogWithMark("network changed. Checking to see if it was WiFi...")
            if path.status != .satisfied {
                TCSLogErrorWithMark("not connected")
            }
            else if path.usesInterfaceType(.cellular) {
                TCSLogWithMark("Cellular")
            }
            else if path.usesInterfaceType(.wifi) {
                TCSLogWithMark("Wifi changed")
                self.timer?.invalidate()

                self.monitor?.cancel()
                self.delegate?.networkManagerConnectedToNetwork?()
            }
            else if path.usesInterfaceType(.wiredEthernet) {
                TCSLogWithMark("Ethernet")
            }
            else if path.usesInterfaceType(.other){
                TCSLogWithMark("Other")
            }
            else if path.usesInterfaceType(.loopback){
                TCSLogWithMark("Loop Back")
            }
            else {
                TCSLogWithMark("Unknown interface type")
            }


        }
        let queue = DispatchQueue(label: "Monitor2")
        monitor?.start(queue: queue)

    }

}
