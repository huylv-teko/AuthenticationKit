//
//  TekoOAuthHelper.swift
//  VNShop
//
//  Created by linhvt on 1/6/20.
//  Copyright © 2020 Teko. All rights reserved.
//

import Foundation
import TekoOAuth


class TekoOAuthHelper {
    
    static let shared = TekoOAuthHelper()
    
    private let authConfig = TekoOIDConfiguration(
        clientId: Configs.OAuth.clientId,
        redirectUri: Configs.OAuth.redirectUri,
        scopes: ["openid", "profile"],
        oauthDomain: Configs.OAuth.domain)
    
    private var authManager: TekoOID {
        return TekoOID(appDelegate: UIApplication.shared.delegate as! TekoOIDAppDelegate, tekoOIDConfiguration: authConfig)
    }
    
    var token: String? {
        Log.i("+++ token: \(authManager.getAccessToken() ?? "") \n userid \(authManager.getUserId() ?? "")")
        return authManager.getAccessToken()
    }
    
    var userId: String? {
        return authManager.getUserId()
    }
    
    var isLoggedIn: Bool {
        return !userId.isNilOrEmpty && !token.isNilOrEmpty && authManager.isAuthorized()
    }
    
    func loginFacebook(presenting vc: UIViewController, completion: OAuthLoginHandler?) {
        authManager.authenticateByFacebook(presenting: vc) { (isSuccess, error) in
            let message = error?.localizedDescription
            completion?(isSuccess, message)
        }
    }
    
    func loginGoogle(presenting vc: UIViewController, completion: OAuthLoginHandler?) {
        authManager.authenticateByGoogle(presenting: vc) { (isSuccess, error) in
            let message = error?.localizedDescription
            completion?(isSuccess, message)
        }
    }
    
    func logOut() {
        authManager.logOut()
    }
    
}
