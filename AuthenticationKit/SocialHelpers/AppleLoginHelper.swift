//
//  AppleLoginHelper.swift
//  VNShop
//
//  Created by linhvt on 1/6/20.
//  Copyright © 2020 Teko. All rights reserved.
//

import Foundation
import AuthenticationServices

public typealias AppleTokenHandler = (String?, String?) -> Void

public protocol AppleLoginHelperDelegate: class {
    func loginAppleSuccess(userInfo: AppleUserInfo)
    func loginAppleFailed(message: String)
}

public struct AppleProfile {
    public let id: String
    public let name: String
    let email: String
}

public struct AppleUserInfo {
    public let token: String
    public let profile: AppleProfile?
}


public class AppleLoginHelper: NSObject {
    public weak var delegate: AppleLoginHelperDelegate?
    public static let shared = AppleLoginHelper()
    
    @available(iOS 13.0, *)
    public func login(with presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?) {
        let authorizationProvider = ASAuthorizationAppleIDProvider()
        let request = authorizationProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = presentationContextProvider
        authorizationController.performRequests()
    }
    
    public func logOut() {
        LoginUserDefaultsManager.clearValueInUserDefaults(KeyUserDefaults.appleUsernameType)
        LoginUserDefaultsManager.clearValueInUserDefaults(KeyUserDefaults.appleUserID)
        LoginUserDefaultsManager.clearValueInUserDefaults(KeyUserDefaults.appleToken)
    }
    
    public func getAccessToken(completion: AppleTokenHandler?) {
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let appleID = LoginUserDefaultsManager.getStringInUserDefaults(KeyUserDefaults.appleUserID)
            guard !appleID.isEmpty else {
                completion?(nil, nil)
                return
            }
            appleIDProvider.getCredentialState(forUserID: appleID) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    let appleToken = LoginUserDefaultsManager.getStringInUserDefaults(KeyUserDefaults.appleToken)
                    let appleUsername = LoginUserDefaultsManager.getStringInUserDefaults(KeyUserDefaults.appleUsername)
                    guard !appleToken.isEmpty else {
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
    
}

// MARK: ASAuthorizationControllerDelegate
extension AppleLoginHelper: ASAuthorizationControllerDelegate {
    
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            delegate?.loginAppleFailed(message: "empty credential")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken, let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch identity token")
            delegate?.loginAppleFailed(message: "empty token")
            return
        }
        LoginUserDefaultsManager.saveStringInUserDefaults(idTokenString, KeyUserDefaults.appleToken)
        let userIdentifier = appleIDCredential.user
        var fullName = appleIDCredential.fullName?.familyName ?? ""
        if let givenName = appleIDCredential.fullName?.givenName {
            fullName += " \(givenName)"
        }
        let email = appleIDCredential.email
        print("AppleID Credential Authorization: userId: \(userIdentifier), email: \(String(describing: email)), fullName: \(String(describing: fullName))")
        let profile = AppleProfile(id: userIdentifier, name: fullName, email: email ?? "")
        let userInfo = AppleUserInfo(token: idTokenString, profile: profile)
        delegate?.loginAppleSuccess(userInfo: userInfo)
        
    }
    
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("AppleID Credential failed with error: \(error.localizedDescription)")
        delegate?.loginAppleFailed(message: error.localizedDescription)
    }
    
}
