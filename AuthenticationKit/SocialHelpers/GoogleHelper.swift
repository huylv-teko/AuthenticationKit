//
//  GoogleHelper.swift
//  VNShop
//
//  Created by linhvt on 2/12/20.
//  Copyright © 2020 Teko. All rights reserved.
//

import UIKit
import GoogleSignIn

protocol GoogleHelperDelegate: class {
    func loginGoogleSuccess(userInfo: GoogleUserInfo)
    func loginGoogleFailed(message: String)
}

struct GoogleProfile {
    let id: String
    let name: String
    let avatar: String
    let email: String
}

struct GoogleUserInfo {
    let token: String
    let profile: GoogleProfile?
}


class GoogleHelper: NSObject {
    weak var delegate: GoogleHelperDelegate?
    static let sharedInstance = GoogleHelper()
    static let kGoogleAccessToken = "KEY_GOOGLE_ACCESS_TOKEN"
    private let gSignIn = GIDSignIn.sharedInstance()
    
    func login(presentVC: UIViewController) {
        gSignIn?.delegate = self
        gSignIn?.presentingViewController = presentVC
        gSignIn?.signIn()
    }
    
    func restorePreviousSignIn() {
        if (gSignIn?.hasPreviousSignIn() == true) {
            gSignIn?.restorePreviousSignIn()
        }
    }
    
    func logout() {
        gSignIn?.signOut()
    }
    
    func getAccessToken() -> String? {
        return gSignIn?.currentUser?.authentication?.accessToken
    }
    
    deinit {
//        print("deinit")
    }
    
}

// MARK: - GIDSignInDelegate
extension GoogleHelper: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            delegate?.loginGoogleFailed(message: error.localizedDescription)
            return
        }
        // Perform any operations on signed in user here.
        let userId = user.userID                  // For client-side use only!
        let idToken = user.authentication.idToken // Safe to send to the server
        let accessToken = user.authentication.accessToken
        let fullName = user.profile.name
        let email = user.profile.email
        var avatar = ""
        if user.profile.hasImage {
            let pic = user.profile.imageURL(withDimension: 100).absoluteString
            avatar = pic
        }
        
        if let token = accessToken {
            NSUserDefaultsManager.saveStringInUserDefaults(token, GoogleHelper.kGoogleAccessToken)
            let profile = GoogleProfile(id: userId ?? "", name: fullName ?? "", avatar: avatar, email: email ?? "")
            let userInfo = GoogleUserInfo(token: token, profile: profile)
            delegate?.loginGoogleSuccess(userInfo: userInfo)
        } else {
            delegate?.loginGoogleFailed(message: "empty token")
        }
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("disconnect")
    }
}

