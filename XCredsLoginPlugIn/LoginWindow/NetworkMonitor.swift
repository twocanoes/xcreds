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


    private(set) var lastNotification = Date.distantPast

    private init() {
        monitor = NWPathMonitor(prohibitedInterfaceTypes: [.cellular, .loopback])
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            TCSLogWithMark("Network monitor: path updated")
            let currentConnectionType = NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
            TCSLogWithMark("Network monitor: connectivity status \"\(path.status)\" for \(String(describing: currentConnectionType))")
            if path.status == .satisfied {
                TCSLogWithMark("Network monitor: connected to network")
                if let lastNotification = self?.lastNotification, abs(lastNotification.timeIntervalSinceNow) > 5 {
                    self?.lastNotification = Date()
                    NotificationCenter.default.post(name: .connectivityStatus, object: nil)
                }
                else {
                    TCSLogWithMark("Network monitor: skipping connectivity status notification since less than 5 seconds since last notification")
                }

            }
            else {
                TCSLogWithMark("Not connected to network, not posting any notifications")

            }

        }
        self.monitor.start(queue: queue)

    }

    func stopMonitoring() {
        TCSLogWithMark("Network monitor: stopping")
        monitor.cancel()
    }
}
