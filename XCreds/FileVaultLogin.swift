//
//  FileVaultLogin.swift
//  XCreds
//
//  Created by Timothy Perfitt on 10/10/25.
//

import ServiceManagement


class FileVaultLoginHelper {
    
    static let shared = FileVaultLoginHelper()

    
    func skipFileVaultAuthAtNextReboot(completion:@escaping(_ result:Bool, _ error:String?)->Void)   {
        let helperToolManager = HelperToolManager()

        switch  helperToolManager.manageHelperTool(action: .install) {
            
        case .notRegistered:
            TCSLogWithMark()
            
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
        helperToolManager.runCommand(username:username, password:cred.password) { success in
            if success==true{
                TCSLogWithMark("runCommand success")
                TCSLogWithMark()
                completion(true, "")

            }
            else {
                TCSLogWithMark()
//                NSAlert.showAlert(title:"Error",message:"Cannot set filevault login")
                TCSLogWithMark()
                completion(false, "Cannot set filevault login")
            }

        }

    }
    func skipFileVaultAuthAtNextRebootWithAdmin( completion:@escaping(_ result:Bool, _ error:String?)->Void)   {
        let helperToolManager = HelperToolManager()

        switch  helperToolManager.manageHelperTool(action: .install) {
            
        case .notRegistered:
            TCSLogWithMark()
            
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
        do {
            
                helperToolManager.authFVAsAdmin() { success in
                    if success==true{
                        TCSLogWithMark("runCommand success")
                    }
                    else {
                        TCSLogWithMark("Cannot set filevault login as admin")
//                        NSAlert.showAlert(title:"Error",message:"Cannot set filevault login as admin")
                    }
                    TCSLogWithMark()
                    completion(success, "")
                }
               

//            }
//            else {
//                
//                TCSLogWithMark("no valid credentials for admin filevault unlock")
//                completion(false, "no valid credentials for admin filevaulit unlock")
//
//            }
            
        }
        catch {
            TCSLogWithMark("error setting filevault login as admin")
            completion(false, "error setting filevault login as admin")

        }

      
    }
    
}
