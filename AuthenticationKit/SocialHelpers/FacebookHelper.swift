//
//  FacebookHelper.swift
//  VNShop
//
//  Created by linhvt on 2/12/20.
//  Copyright © 2020 Teko. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKLoginKit
import SwiftyJSON

typealias GetFacebookUserInfoHandler = (_ userInfo: FBUserInfo?) -> Void

enum FacebookError {
    case failed(msg: String)
    case cancelled
    case emptyToken
    case emptyProfile
}

protocol FacebookHelperDelegate: class {
    func loginFacebookSucceeded(userInfo: FBUserInfo)
    func loginFacebookFailed(error: FacebookError)
}

struct FBProfile {
    let id: String
    let name: String
    let avatar: String
    let gender: String
    let email: String
}

struct FBUserInfo {
    let token: String
    let profile: FBProfile?
}

class FacebookHelper: NSObject {
    
    static let sharedInstance = FacebookHelper()
    weak var delegate: FacebookHelperDelegate?
    
    func login(presentVC: UIViewController) {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: [.publicProfile, .email], viewController: presentVC) { [weak self] (loginResult) in
            switch loginResult {
            case .failed(let error):
                print(error)
                self?.delegate?.loginFacebookFailed(error: .failed(msg: error.localizedDescription))
            case .cancelled:
                print("User has cancelled login.")
                self?.delegate?.loginFacebookFailed(error: .cancelled)
            case .success( _,  _, let accessToken):
                print("Logged in with accessToken: \(accessToken.tokenString)")
                // cancel getFacebookInfo
                self?.delegate?.loginFacebookSucceeded(userInfo: FBUserInfo(token: accessToken.tokenString, profile: nil))
            }
        }
    }
    
    func getAccessToken() -> String? {
        return AccessToken.current?.tokenString
    }
    
    func getFacebookInfo(completion: GetFacebookUserInfoHandler?) {
        if let token = getAccessToken() {
            GraphRequest(graphPath: "me", parameters: ["fields": "id, name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil) {
                    let json = JSON.init(result as Any)
                    print(json)
                    let id = json["id"].stringValue
                    let name = json["name"].stringValue
                    let gender = json["gender"].stringValue
                    let email = json["email"].stringValue
                    var avatar = ""
                    let pictureJson = json["picture"].dictionaryValue
                    if let dataPicture = pictureJson["data"]?.dictionaryValue {
                        avatar = dataPicture["url"]?.stringValue ?? ""
                    }
                    let profile = FBProfile(id: id, name: name, avatar: avatar, gender: gender, email: email)
                    completion?(FBUserInfo(token: token, profile: profile))
                } else {
                    completion?(FBUserInfo(token: token, profile: nil))
                }
            })
        } else {
            completion?(nil)
        }
    }
    
    func logout() {
        let loginManager = LoginManager()
        loginManager.logOut()
    }
    
}
