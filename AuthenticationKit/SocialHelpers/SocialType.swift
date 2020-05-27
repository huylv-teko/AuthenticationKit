//
//  SocialType.swift
//  VNShop
//
//  Created by linhvt on 1/6/20.
//  Copyright © 2020 Teko. All rights reserved.
//

import Foundation

public enum SocialType: String {
    case facebook
    case google
    case apple
    case phone

    public var authorizer: String {
        switch self {
        case .facebook:
            return "facebook"
        case .google:
            return "google"
        case .apple:
            return "apple"
        case .phone:
            return "phone"
        }
    }

    public static func initialize(type: String?) -> SocialType? {
        guard let type = type else { return nil }
        switch type {
        case "facebook":
            return .facebook
        case "google":
            return .google
        case "apple":
            return .apple
        case "phone":
            return .phone
        default:
            return nil
        }
    }
    
}
