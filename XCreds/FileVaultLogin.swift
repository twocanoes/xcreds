//
//  FileVaultLogin.swift
//  XCreds
//
//  Created by Timothy Perfitt on 10/10/25.
//

import ServiceManagement


class FileVaultLoginHelper {
    
    static let shared = FileVaultLoginHelper()

    
    func skipFileVaultAuthAtNextReboot(completion:(_ result:Bool, _ error:String?)->Void)   {
        let helperToolManager = HelperToolManager()

        switch  helperToolManager.manageHelperTool(action: .install) {
            
        case .notRegistered:
            TCSLogWithMark()
            
//            NSAlert.showAlert(title: "Error", message:"Service is not registered")
            completion(false, "Service is not registered")
            
            return
        case .enabled:
            TCSLogWithMark()
            
            break
        case .requiresApproval:
            TCSLogWithMark("Service requires approval. Please select Allow in the notification or open System Preferences->Login Items and allow the service")
            
            completion(false, "Service requires approval. Please select Allow in the notification or open System Preferences->Login Items and allow the service")

        case .notFound:
            TCSLogWithMark("Service Not Found")
            completion(false, "Service Not Found")

        @unknown default:
            TCSLogWithMark("Unknown Error")
            completion(false, "Unknown Error")
        }
        
        TCSLogWithMark()
        
        let username = getConsoleUser()
        let cred = KeychainUtil().findPassword(serviceName: PrefKeys.password.rawValue, accountName: PrefKeys.password.rawValue)
        TCSLogWithMark()
        
        guard let cred = cred else {
            
            TCSLogWithMark("no valid password found")
            completion(false, "no valid password found")
            return
        }
        helperToolManager.runCommand(username:username, password:cred.password) { output in
            if output==true{
                TCSLogWithMark("runCommand success")
            }
            else {
                TCSLogWithMark()
                NSAlert.showAlert(title:"Error",message:"Cannot set filevault login")
            }
        }
        TCSLogWithMark()
        completion(true, "")

    }
    
}
