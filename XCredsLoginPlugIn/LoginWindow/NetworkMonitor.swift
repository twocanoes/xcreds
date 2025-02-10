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
        monitor.pathUpdateHandler = { [weak self] path in
            TCSLogWithMark("Network monitor: path updated")
            self?.isConnected = path.status == .satisfied
            self?.isExpensive = path.isExpensive
            self?.currentConnectionType = NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
            if NetworkManager().isConnectedToNetwork() == true {
                TCSLogWithMark("Network monitor: connected to network")
                if let lastNotification = self?.lastNotification {
                    if abs(lastNotification.timeIntervalSinceNow) > 5 {
                        TCSLogWithMark("Network monitor: posting connectivity status to NC: \(path.status) for \(String(describing: self?.currentConnectionType))")
                        self?.lastNotification = Date()
                        NotificationCenter.default.post(name: .connectivityStatus, object: nil)
                    } else {
                        TCSLogWithMark("Network monitor: debouncing connectivity status to NC")
                    }
                } else {
                    TCSLogWithMark("Network monitor: posting connectivity status to NC: \(path.status) for \(String(describing: self?.currentConnectionType))")
                    self?.lastNotification = Date()
                    NotificationCenter.default.post(name: .connectivityStatus, object: nil)
                }
            } else {
                TCSLogWithMark("Not connected to network, no notfication posted")
                self?.isConnected=false
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        TCSLogWithMark("Network monitor: stopping")
        monitor.cancel()
    }
}
