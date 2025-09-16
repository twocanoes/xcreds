//
//  CredentialProviderViewController.swift
//  XCreds AutoFill Extension
//
//  Created by Timothy Perfitt on 6/5/24.
//

import AuthenticationServices
import LocalAuthentication
@available(macOS, deprecated: 11)

class CredentialProviderViewController: ASCredentialProviderViewController {

    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
    */
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    }

    /*
     Implement this method if your extension supports showing credentials in the QuickType bar.
     When the user selects a credential from your app, this method will be called with the
     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
     Provide the password by completing the extension request with the associated ASPasswordCredential.
     If using the credential would require showing custom UI for authenticating the user, cancel
     the request with error code ASExtensionError.userInteractionRequired.

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        let databaseIsUnlocked = true
        if (databaseIsUnlocked) {
            let passwordCredential = ASPasswordCredential(user: "j_appleseed", password: "apple1234")
            self.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
        } else {
            self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code:ASExtensionError.userInteractionRequired.rawValue))
        }
    }
    */

    /*
     Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
    }
    */

    override func viewDidAppear() {
        passwordSelected(self)

    }
    @IBAction func cancel(_ sender: AnyObject?) {
        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }

    @IBAction func passwordSelected(_ sender: AnyObject?) {
        let keychainUtil = KeychainUtil()

        let keychainAccountAndPassword = try? keychainUtil.findPassword(serviceName: "xcreds local password",accountName:PrefKeys.password.rawValue)

        guard let keychainAccountAndPassword = keychainAccountAndPassword  else {
            TCSLogWithMark("No keychainAccountAndPassword")
            self.extensionContext.cancelRequest(withError: NSError(domain: "none", code: -1))

            return
        }
        var dsUsername:String?
        let currentUser = PasswordUtils.getCurrentConsoleUserRecord()
        if let userNames = try? currentUser?.values(forAttribute: "dsAttrTypeNative:_xcreds_oidc_full_username") as? [String], userNames.count>0, let username = userNames.first {
            TCSLogWithMark()
            dsUsername = username

        }
        else if let userNames = try? currentUser?.values(forAttribute: "dsAttrTypeNative:_xcreds_activedirectory_kerberosPrincipal") as? [String], userNames.count>0, let username = userNames.first {
            TCSLogWithMark()
            dsUsername = username

        }
        guard let dsUsername = dsUsername else {
            TCSLogWithMark("Invalid dsUsername")
            self.extensionContext.cancelRequest(withError: NSError(domain: "none", code: -1))

            return
        }

        let passwordCredential = ASPasswordCredential(user: dsUsername, password: keychainAccountAndPassword.1 ?? "")


        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "XCreds Login Password"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in

                DispatchQueue.main.async {
                    if success {
                        self?.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
                        
                    } else {
                        self?.extensionContext.cancelRequest(withError: NSError(domain: "none", code: -1))
                    }
                }
            }
        }
        else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "XCreds Login Password"

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                [weak self] success, authenticationError in

                DispatchQueue.main.async {
                    if success {
                        self?.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)

                    } else {
                        self?.extensionContext.cancelRequest(withError: NSError(domain: "none", code: -1))
                    }
                }
            }
        }
        else {
            self.extensionContext.cancelRequest(withError: NSError(domain: "none", code: -1))
        }
    }

}
