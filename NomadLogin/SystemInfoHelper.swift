//
//  SystemInfoHelper.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 3/31/20.
//  Copyright © 2020 Orchard & Grove. All rights reserved.
//

import Foundation

import NetworkExtension

class SystemInfoHelper {
    
    func info() -> [String] {
        var info = [String]()
        
        info.append("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        info.append("Serial: \(getSerial())")
        info.append("MAC: \(getMAC())")
        info.append("Computer Name: \(Host.current().localizedName!)")
        info.append("Hostname: \(ProcessInfo.processInfo.hostName)")

        if let ssid = WifiManager().getCurrentSSID(){
            info.append("SSID: \(ssid)")
        }

        let ipAddresses = getIFAddresses()
        if ipAddresses.count > 0 {
            info.append("IP Address: \(ipAddresses[0])")
        }
        
        return info
    }
    
    func ipAddress() -> String? {
        let ipAddresses = getIFAddresses()

        if ipAddresses.count>0{
            return ipAddresses[0]
        }
        return nil
    }
    private func getIFAddresses() -> [String] {
        var addresses = [String]()

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }

        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        if !address.contains(":"){
                            addresses.append(address)
                        }
                    }
                }
            }
        }

        freeifaddrs(ifaddr)
        return addresses
    }
}
