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
    private var shottaImage: ShottaImage? = nil

    public private(set) var imageArray: [[String: Any]]? = nil

    // Initializers
    init(email: String, password: String) {
        super.init()
        self.login(email: email, password: password)
    }
    
    private func setupImage(){
        if shottaImage == nil{
            self.shottaImage = ShottaImage(user: self)
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
    public func uploadImage(image: UIImage) throws{
        if self.state == .authenticated {
            setupImage()
            let data = UIImagePNGRepresentation(image)
            do {
                try self.shottaImage?.uploadImageData(data: data!)
            } catch _ {
                throw "Error setting array to user"
            }
            
        }else{
            throw "User not authenticated"
        }

    }

    // Get images
    public func loadImages() throws {
        if self.state == .authenticated {
            setupImage()
            do {
                try imageArray = self.shottaImage?.getAllImages()
                
            } catch _ {
                throw "Error setting array to user"
            }

        }else{
            throw "User not authenticated"
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
        }

    }
    // TO-DO: Logout :P
}
enum ShottaState {
    case authenticated
    case unauthenticated
}
