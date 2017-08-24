//
//  ShottaUser.swift
//  Shotta-iOS
//
//  Created by Keaton Burleson on 8/22/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

class ShottaUser: NSObject {

    #if DEBUG
        private let urlString = "http://localhost:3000/api/v1/"
    #else
        private let urlString = "http://shotta.128keaton.com/api/v1/"
    #endif

    private var state: ShottaState = .unauthenticated
    private var authToken: String? = nil
    private var shotta: Shotta? = nil
    public var delegate: ShottaUserDelegate? = nil

    // Initializers
    init(email: String, password: String) {
        super.init()
        self.login(email: email, password: password)
    }

    init(authToken: String) {
        super.init()
        self.setupShotta()
        self.shotta?.tokenIsValid(authToken, completionHandler: { (isValid, error) in
            if isValid == true && error == nil {
                self.state = .authenticated
                self.setAuthToken(token: authToken)
                self.delegate?.authenticationChanged(state: self.state)
            } else {
                self.delegate?.authenticationChanged(state: self.state)
            }
        })

    }

    private func setupShotta() {
        if shotta == nil {
            self.shotta = Shotta(user: self)
        }
    }


    // Authentication Token
    public func getAuthToken() -> String? {
        return self.authToken
    }
    private func setAuthToken(token: String) {
        self.authToken = token
    }

    // State
    public func getState() -> ShottaState {
        return self.state
    }

    public func setShottaDelegate(delegate: ShottaDelegate) {
        self.setupShotta()
        self.shotta?.delegate = delegate
    }

    public func uploadImage(image: UIImage) throws {
        if self.state == .authenticated {
            let data = UIImagePNGRepresentation(image)
            do {
                try self.shotta?.uploadImageData(data: data!)
            } catch _ {
                throw "Error setting array to user"
            }

        } else {
            throw "User not authenticated"
        }

    }

    public func loadImages() {
        if self.state == .authenticated {
            try! self.shotta?.getAllImages()
        }
    }

    // Login/Logout
    private func login(email: String, password: String) {
        let loginParameters = ["user_login[email]": email, "user_login[password]": password]
        Alamofire.request(urlString + "sign-in", method: .post, parameters: loginParameters, encoding: URLEncoding.default, headers: nil).responseJSON {
            response in
            switch response.result {
            case .success:
                if let data = response.result.value {
                    self.setAuthToken(token: (data as! [String: String])["auth_token"]!)
                }
                #if DEBUG
                    print(response)
                #endif
                self.state = .authenticated

                break
            case .failure(let error):
                #if DEBUG
                    print(error)
                #endif
                break
            }
            self.delegate?.authenticationChanged(state: self.state)
        }

    }
    // TO-DO: Logout :P
    
    public func logout(completionHandler: @escaping (ShottaState, Error?) -> ()) {
        // Special case
        let headers: HTTPHeaders = [
            "X-AUTH-TOKEN": self.authToken!,
            "Accept": "application/json"
        ]
        
        Alamofire.request(urlString + "sign-out", method: .delete, parameters: [:], encoding: URLEncoding.default, headers: headers).responseJSON {
            response in
            switch response.result {
            case .success:
                #if DEBUG
                    print(response)
                #endif
                self.state = .unauthenticated
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "auth-token")
                defaults.synchronize()
                completionHandler(.unauthenticated, nil)
                break
            case .failure(let error):
                #if DEBUG
                    print(error)
                #endif
                completionHandler(.authenticated, error)
                break
            }
            self.delegate?.authenticationChanged(state: self.state)
        }
    }
}
enum ShottaState {
    case authenticated
    case unauthenticated
}
protocol ShottaUserDelegate {
    func authenticationChanged(state: ShottaState)
}
