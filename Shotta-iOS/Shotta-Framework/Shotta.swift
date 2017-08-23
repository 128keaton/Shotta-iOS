//
//  ShottaImage.swift
//  Shotta-iOS
//
//  Created by Keaton Burleson on 8/23/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import Alamofire

class Shotta: NSObject {
    #if DEBUG
        fileprivate let urlString = "http://localhost:3000/api/v1/"
    #else
        fileprivate let urlString = "http://shotta.128keaton.com/api/v1/"
    #endif


    fileprivate var user: ShottaUser? = nil
    var delegate: ShottaDelegate? = nil
    
    init(user: ShottaUser) {
        super.init()
        self.user = user
    }

    // Generate headers
    fileprivate func getHeaders() throws -> HTTPHeaders {
        guard let currentUser = self.user
            else {
                throw "Current user not set"
        }

        guard let authToken = currentUser.getAuthToken()
            else {
                throw "Auth token on user not set"
        }

        let headers: HTTPHeaders = [
            "X-AUTH-TOKEN": authToken,
            "Accept": "application/json"
        ]
        return headers
    }

    // Upload image
    public func uploadImageData(data: Data) throws {

        var headers: HTTPHeaders? = nil

        do {
            try headers = getHeaders()
        } catch _ {
            throw "Error getting headers"
        }
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(data, withName: "file", fileName: "photo.jpeg", mimeType: "image/jpeg")

        }, usingThreshold: UInt64.init(), to: urlString + "upload", method: .post, headers: headers) { (result) in
            print(result)
        }

    }

    
    // Get all images for user
    public func getAllImages() throws{
        var headers: HTTPHeaders? = nil

        do {
            try headers = getHeaders()
        } catch _ {
            throw "Error getting headers"
        }
        
        Alamofire.request(urlString + "show", headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success:
                    #if DEBUG
                        print(response.result.value!)
                    #endif
                    self.delegate?.imagesDidUpdate(images: response.result.value as! [[String: Any]])
                    break
                case .failure(let error):
                    #if DEBUG
                        print(error)
                    #endif
                    break
                }

        }
    }

}
extension String: Error { }

// Define ShottaDelegate
protocol ShottaDelegate{
    func imagesDidUpdate(images: [[String: Any]])
}

