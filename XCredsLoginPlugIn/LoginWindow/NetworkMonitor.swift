//
//  NetworkMonitor.swift
//  XCredsLoginPlugin
//
//  Created by Carlos Hernandez on 2023-10-22.
//

import Foundation
import Network

extension Notification.Name {
    static let connectivityStatus = Notification.Name(rawValue: "connectivityStatusChanged")
}

extension NWInterface.InterfaceType: @retroactive CaseIterable {
    public static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet
    ]
}

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")
    private let monitor: NWPathMonitor

    private(set) var isConnected = false
    private(set) var isExpensive = false
    private(set) var lastNotification: Date?
    private(set) var currentConnectionType: NWInterface.InterfaceType?

    private init() {
        monitor = NWPathMonitor(prohibitedInterfaceTypes: [.cellular, .loopback])
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied,NetworkManager().isConnectedToNetwork() == true {
                self.isConnected=true
            } else {
                self.isConnected=false
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        TCSLogWithMark("Network monitor: stopping")
        monitor.cancel()
    }
}
