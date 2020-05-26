//
//  AppleLoginHelper.swift
//  VNShop
//
//  Created by linhvt on 1/6/20.
//  Copyright © 2020 Teko. All rights reserved.
//

import Foundation
import AuthenticationServices

typealias AppleTokenHandler = (String?, String?) -> Void

protocol AppleLoginHelperDelegate: class {
    func loginAppleSuccess(userInfo: AppleUserInfo)
    func loginAppleFailed(message: String)
}

struct AppleProfile {
    let id: String
    let name: String
    let email: String
}

struct AppleUserInfo {
    let token: String
    let profile: AppleProfile?
}


class AppleLoginHelper: NSObject {
    weak var delegate: AppleLoginHelperDelegate?
    static let shared = AppleLoginHelper()
    
    @available(iOS 13.0, *)
    func login(with presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?) {
        let authorizationProvider = ASAuthorizationAppleIDProvider()
        let request = authorizationProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = presentationContextProvider
        authorizationController.performRequests()
    }
    
    func logOut() {
        NSUserDefaultsManager.clearValueInUserDefaults(KeyUserDefaults.appleUsernameType)
        NSUserDefaultsManager.clearValueInUserDefaults(KeyUserDefaults.appleUserID)
        NSUserDefaultsManager.clearValueInUserDefaults(KeyUserDefaults.appleToken)
    }
    
    func getAccessToken(completion: AppleTokenHandler?) {
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let appleID = NSUserDefaultsManager.getStringInUserDefaults(KeyUserDefaults.appleUserID)
            guard appleID.isNotEmpty else {
                completion?(nil, nil)
                return
            }
            appleIDProvider.getCredentialState(forUserID: appleID) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    let appleToken = NSUserDefaultsManager.getStringInUserDefaults(KeyUserDefaults.appleToken)
                    let appleUsername = NSUserDefaultsManager.getStringInUserDefaults(KeyUserDefaults.appleUsername)
                    guard appleToken.isNotEmpty else {
                        fallthrough
                    }
                    completion?(appleToken, appleUsername)
                default:
                    self.logOut()
                    completion?(nil, nil)
                }
            }
        } else {
            // Fallback on earlier versions
            completion?(nil, nil)
        }
    }
    
    deinit {
        Log.i("deinit")
    }
    
}

// MARK: ASAuthorizationControllerDelegate
extension AppleLoginHelper: ASAuthorizationControllerDelegate {
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            delegate?.loginAppleFailed(message: "empty credential")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken, let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch identity token")
            delegate?.loginAppleFailed(message: "empty token")
            return
        }
        NSUserDefaultsManager.saveStringInUserDefaults(idTokenString, KeyUserDefaults.appleToken)
        let userIdentifier = appleIDCredential.user
        var fullName = appleIDCredential.fullName?.familyName ?? ""
        if let givenName = appleIDCredential.fullName?.givenName {
            fullName += " \(givenName)"
        }
        let email = appleIDCredential.email
        Log.i("AppleID Credential Authorization: userId: \(userIdentifier), email: \(String(describing: email)), fullName: \(String(describing: fullName))")
        let profile = AppleProfile(id: userIdentifier, name: fullName, email: email ?? "")
        let userInfo = AppleUserInfo(token: idTokenString, profile: profile)
        delegate?.loginAppleSuccess(userInfo: userInfo)
        
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Log.i("AppleID Credential failed with error: \(error.localizedDescription)")
        delegate?.loginAppleFailed(message: error.localizedDescription)
    }
    
}
