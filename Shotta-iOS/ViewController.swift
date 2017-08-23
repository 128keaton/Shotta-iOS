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

    private let picker = UIImagePickerController()

    private var user: ShottaUser? = nil
    private var userImage: ShottaImage? = nil

    @IBOutlet var sampleImageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUser()
        picker.delegate = self
    }

    func setupUser() {
        if self.user == nil {
            self.user = ShottaUser(email: "test.user@me.com", password: "abc123")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func uploadImage(image: UIImage) {
        do {
            try self.user?.uploadImage(image: image)
        } catch _ {
            print("Error uploading image")
            setupUser()
            self.uploadImage(image: image)
        }

    }





    @IBAction func showLatestImage() {
        do {
            try self.user?.loadImages()
        } catch _ {
            print(user?.getState())
            print("Error uploading image")
        }
        
        let imageArray: [[String: Any]]! = self.user?.imageArray
        if imageArray?.count != 0 {
            let imageParent = imageArray?.last
            let imageObject = imageParent?["image"] as? [String: String]
            let imageUrl = imageObject?["url"]

            if let checkedUrl = URL(string: imageUrl!) {
                self.downloadImage(url: checkedUrl)
            }

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
            self.uploadImage(image: editedImage)
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {

            self.uploadImage(image: originalImage)
        } else {
            print ("error")
        }
        picker.dismiss(animated: true, completion: nil)

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

}

