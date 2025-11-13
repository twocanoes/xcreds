//
//  HelperToolManager.swift
//  HelperToolApp
////
import ServiceManagement

@objc(HelperToolProtocol)
public protocol HelperToolProtocol {
    func runCommand(username:String, password:String, withReply reply: @escaping (Bool) -> Void)
    
    func authFVAsAdmin(withReply reply: @escaping (Bool) -> Void)

    
}

enum HelperToolAction {
    case none      // Only check status
    case install   // Install the helper tool
    case uninstall // Uninstall the helper tool
}


class HelperToolManager: ObservableObject {
    private var helperConnection: NSXPCConnection?
    let helperToolIdentifier = "com.twocanoes.FileVaultLoginHelper"
     var isHelperToolInstalled: Bool = false
    @Published var message: String = "Checking..."
    var status: String {
        return isHelperToolInstalled ? "Registered" : "Not Registered"
    }

//    init() {
//            manageHelperTool()
//        
//    }

    // Function to manage the helper tool installation/uninstallation
    func manageHelperTool(action: HelperToolAction = .none) -> SMAppService.Status {
        let plistName = "\(helperToolIdentifier).plist"
        let service = SMAppService.daemon(plistName: plistName)
        var occurredError: NSError?

        // Perform install/uninstall actions if specified
        switch action {
        case .install:
            // Pre-check before registering
            switch service.status {
            case .requiresApproval:
                message = "Registered but requires enabling in System Settings > Login Items."
                SMAppService.openSystemSettingsLoginItems()
            case .enabled:
                message = "Service is already enabled."
            default:
                do {
                    try service.register()
                    if service.status == .requiresApproval {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                } catch let nsError as NSError {
                    occurredError = nsError
                    if nsError.code == 1 { // Operation not permitted
                        message = "Permission required. Enable in System Settings > Login Items."
                        SMAppService.openSystemSettingsLoginItems()
                    } else {
                        message = "Installation failed: \(nsError.localizedDescription)"
                        print("Failed to register helper: \(nsError.localizedDescription)")
                    }

                }
            }

        case .uninstall:
            do {
                try service.unregister()
                // Close any existing connection
                helperConnection?.invalidate()
                helperConnection = nil
            } catch let nsError as NSError {
                occurredError = nsError
                print("Failed to unregister helper: \(nsError.localizedDescription)")
            }

        case .none:
            break
        }

        updateStatusMessages(with: service, occurredError: occurredError)
        isHelperToolInstalled = (service.status == .enabled)
        return service.status
    }

    // Function to open Settings > Login Items
    func openSMSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func authFVAsAdmin(withReply completion: @escaping (Bool) -> Void){
        if !isHelperToolInstalled {
            TCSLogWithMark()
            completion(false)
            return
        }

        guard let connection = getConnection() else {
            TCSLogWithMark()
            completion(false)
            return
        }

        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
            DispatchQueue.main.async {
                TCSLogWithMark()
                completion(false)
            }
        }) as? HelperToolProtocol else {
            TCSLogWithMark()
            completion(false)
            return
        }

        proxy.authFVAsAdmin() { output in
            DispatchQueue.main.async {
                TCSLogWithMark()
                completion(true)
            }
        }
    }

    // Function to run privileged commands
    func runCommand(username:String, password:String, withReply completion: @escaping (Bool) -> Void){
        if !isHelperToolInstalled {
            TCSLogWithMark()
            completion(false)
            return
        }

        guard let connection = getConnection() else {
            TCSLogWithMark()
            completion(false)
            return
        }

        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
            DispatchQueue.main.async {
                TCSLogWithMark()
                completion(false)
            }
        }) as? HelperToolProtocol else {
            TCSLogWithMark()
            completion(false)
            return
        }

        proxy.runCommand(username:username, password:password) { output in
            DispatchQueue.main.async {
                TCSLogWithMark()
                completion(true)
            }
        }
    }


    // Create/reuse XPC connection
    private func getConnection() -> NSXPCConnection? {
        TCSLogWithMark()
        if let connection = helperConnection {
            TCSLogWithMark()
            return connection
        }
        let connection = NSXPCConnection(machServiceName: helperToolIdentifier, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
        connection.invalidationHandler = { [weak self] in
            self?.helperConnection = nil
        }
        TCSLogWithMark()
        connection.resume()
        helperConnection = connection
        return connection
    }



    // Helper to update helper status messages
    func updateStatusMessages(with service: SMAppService, occurredError: NSError?) {
        if let nsError = occurredError {
            switch nsError.code {
            case kSMErrorAlreadyRegistered:
                message = "Service is already registered and enabled."
            case kSMErrorLaunchDeniedByUser:
                message = "User denied permission. Enable in System Settings > Login Items."
            case kSMErrorInvalidSignature:
                message = "Invalid signature, ensure proper signing on the application and helper tool."
            case 1:
                message = "Authorization required in Settings > Login Items."
            default:
                message = "Operation failed: \(nsError.localizedDescription)"
            }
        } else {
            switch service.status {
            case .notRegistered:
                message = "Service hasn’t been registered. You may register it now."
            case .enabled:
                message = "Service successfully registered and eligible to run."
            case .requiresApproval:
                message = "Service registered but requires user approval in Settings > Login Items."
            case .notFound:
                message = "Service is not installed."
            @unknown default:
                message = "Unknown service status (\(service.status))."
            }
        }
    }



}
