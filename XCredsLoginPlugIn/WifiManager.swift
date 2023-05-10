//
//  WifiManager.swift
//  JamfConnectLogin
//
//  Created by Adrian Kubisztal on 16/07/2019.
//  Copyright © 2019 Jamf. All rights reserved.
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

@objc protocol WifiManagerDelegate: AnyObject {
    func wifiManagerFullyFinishedInternetConnectionTimer()
    @objc optional func wifiManagerConnectedToNetwork()
}

class WifiManager: CWEventDelegate {
    private var error: Error?
    private var currentInterface: CWInterface?

    var timer: Timer?
    var timerCount: Int = 0 
    let timerMaxRepeatCount = 14
    weak var delegate: WifiManagerDelegate?
    var monitor:NWPathMonitor?

    init() {
        let defaultInterface = CWWiFiClient.shared().interface()
        CWWiFiClient.shared().delegate = self

        do {
            try CWWiFiClient.shared().startMonitoringEvent(with: .ssidDidChange)
        } catch {
            self.error = error
        }

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

    func connectWifi(with network: CWNetwork, password: String?, username: String?, identity: SecIdentity? = nil) -> Bool {
        var result = false
        do {
            TCSLogWithMark("connecting")
            if username != nil && username != "" {
                TCSLogWithMark("connecting \(username ?? "<unknown username")")
                try currentInterface?.associate(toEnterpriseNetwork: network, identity: identity, username: username, password: password)
            } else {
                TCSLogWithMark("connecting with password only \(network)")

                try currentInterface?.associate(to: network, password: password)
                TCSLogWithMark("done associating")

            }
            result = true
        } catch {
            self.error = error
        }
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
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
            return false
        }

        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        return isReachable && !needsConnection
    }

    public func internetConnected() {
        TCSLogWithMark("turning on network monitor")
        configureNetworkMonitor()
        self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: { timer in
            TCSLogWithMark("cancelMonitor")

            self.monitor?.cancel()

        })
//        self.timer = Timer(timeInterval: 30, target: self, selector: #selector(self.cancelMonitor), userInfo: nil, repeats: false)
//        if let timer = self.timer {
//            TCSLogWithMark("firing timer")
//            timer.fire()
//            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
//        }
    }

//    @objc func cancelMonitor(){
//        TCSLogWithMark("cancelMonitor")
//    }
    func configureNetworkMonitor(){
        
        self.monitor = NWPathMonitor()

        monitor?.pathUpdateHandler = { path in
            TCSLogWithMark("network changed. Checking to see if it was WiFi...")
            if path.status != .satisfied {
                TCSLogWithMark("not connected")
            }
            else if path.usesInterfaceType(.cellular) {
                TCSLogWithMark("Cellular")
            }
            else if path.usesInterfaceType(.wifi) {
                TCSLogWithMark("Wifi changed")
                self.timer?.invalidate()

                self.monitor?.cancel()
                self.delegate?.wifiManagerConnectedToNetwork?()
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

//    @objc private func timerCheckInternetConnection() {
//        timerCount = timerCount + 1
//        if self.isConnectedToNetwork() || timerCount >= timerMaxRepeatCount {
//            self.timerCount = 0
//            self.timer?.invalidate()
//            self.timer = nil
//
//            delegate?.wifiManagerFullyFinishedInternetConnectionTimer()
//        }
//
//        if  self.isConnectedToNetwork() {
//            delegate?.wifiManagerConnectedToNetwork?()
//        }
//    }
}
