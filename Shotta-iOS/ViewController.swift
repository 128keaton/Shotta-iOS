//
//  ViewController.swift
//  Shotta-iOS
//
//  Created by Keaton Burleson on 8/22/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var authToken: String? = nil

    private let picker = UIImagePickerController()
    private let urlString = "http://localhost:3000/api/v1/"
    private let loginParameters = ["user_login[email]": "test.user@me.com", "user_login[password]": "abc123"]

    @IBOutlet var sampleImageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        loginTest()
        picker.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



    // Logs in to the backend
    // CURL Example:
    // curl -d "user_login[email]=test.user@me.com&user_login[password]=abc123" http://localhost:3000/api/v1/sign-in --noproxy localhost

    func loginTest() {
        Alamofire.request(urlString + "sign-in", method: .post, parameters: loginParameters, encoding: URLEncoding.default, headers: nil).responseJSON {
            response in
            switch response.result {
            case .success:
                if let data = response.result.value {
                    self.authToken = (data as! [String: String])["auth_token"]!
                    let defaults = UserDefaults(suiteName: "group.shotta.image")
                    defaults?.set(self.authToken!, forKey: "authToken")
                    defaults?.synchronize()
                    print("Synced auth token: \(String(describing: defaults?.object(forKey: "authToken")!))")

                }
                print(response)

                break
            case .failure(let error):

                print(error)
            }
        }
       
    }

    // Lists all the images associated with the account.
    // CURL Example:
    // curl -H "X-AUTH-TOKEN: asdasdasdasdasd"  http://localhost:3000/api/v1/show --noproxy localhost
    @IBAction func showTest() {
        guard let authToken = self.authToken
            else {
                return
        }

        let headers: HTTPHeaders = [
            "X-AUTH-TOKEN": authToken,
            "Accept": "application/json"
        ]


        // This gets tricky. A smart person would parse the JSON into an object.
        // Output:
        /**
        ....
         {
         "created_at" = "2017-08-22T15:36:42.453Z";
         id = 936553;
         image =         {
         url = "https://shotta.s3.amazonaws.com/uploads/screenshot/image/green-fire-9611.jpeg";
         };
         "user_id" = 2;
         }
         ...
         **/
        Alamofire.request(urlString + "show", headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success:
                    print(response.result.value!)
                    let arrayOfObjects = response.result.value as? [[String: Any]]
                    if arrayOfObjects?.count != 0 {
                        let imageParent = arrayOfObjects?.last
                        let imageObject = imageParent?["image"] as? [String: String]
                        let imageUrl = imageObject?["url"]

                        if let checkedUrl = URL(string: imageUrl!) {
                            self.downloadImage(url: checkedUrl)
                        }

                    }

                    break
                case .failure(let error):

                    print(error)
                }

        }
    }

    // Uploads a file to the account
    // CURL Example:
    // curl -H "X-AUTH-TOKEN: asdadasdasd" -X POST -F "file=@doug-paper.png"  http://localhost:3000/api/v1/show --noproxy localhost
    func uploadTest(image: UIImage) {
        guard let authToken = self.authToken
            else {
                return
        }
        let data = UIImagePNGRepresentation(image)
        let headers: HTTPHeaders = [
            "X-AUTH-TOKEN": authToken,
            "Accept": "application/json"
        ]

        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(data!, withName: "file", fileName: "photo.jpeg", mimeType: "image/jpeg")

        }, usingThreshold: UInt64.init(), to: urlString + "upload", method: .post, headers: headers) { (result) in
            print(result)
        }
    }

    // Opens the image picker
    @IBAction func photoFromLibrary() {
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(picker, animated: true, completion: nil)
    }

    // UIImage Fetching method
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
        }.resume()
    }

    func downloadImage(url: URL) {
        print("Download Started")
        getDataFromUrl(url: url) { (data, response, error) in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() { () -> Void in
                self.sampleImageView?.image = UIImage(data: data)
            }
        }
    }

    // Delegate: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {

        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.uploadTest(image: editedImage)
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {

            self.uploadTest(image: originalImage)
        } else {
            print ("error")
        }
        picker.dismiss(animated: true, completion: nil)

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

}

