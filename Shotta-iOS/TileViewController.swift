//
//  TileViewController.swift
//  Shotta
//
//  Created by Keaton Burleson on 8/23/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class TileViewController: UICollectionViewController, ShottaDelegate, UIImagePickerControllerDelegate, ShottaUserDelegate {


    // Properties
    fileprivate var images: [[String: Any]]? = [[:]]
    fileprivate let imagePicker = UIImagePickerController()
    fileprivate var shottaUser: ShottaUser? = nil


    // Delegate: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollection()
        setupShottaUser()
    }

    // Initializers
    private func setupShottaUser() {
        if self.shottaUser == nil {
            self.shottaUser = ShottaUser(email: "test.user@me.com", password: "abc123")
            self.shottaUser?.setShottaDelegate(delegate: self)
            self.shottaUser?.delegate = self
        }
    }

    // Actions
    @IBAction func openImagePicker() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(imagePicker, animated: true, completion: nil)
    }

    // Helpers
    func uploadImage(image: UIImage) {
        do {
            try self.shottaUser?.uploadImage(image: image)
        } catch _ {
            print("Error uploading image")
            self.uploadImage(image: image)
        }

    }
    
    func setupCollection(){
        let layout = UICollectionViewFlowLayout()
        let collectionViewSize = collectionView?.frame.size
        
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let cellsPerRow: CGFloat = 3.0
        let itemSize = (collectionViewSize?.width)!/cellsPerRow
   
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        collectionView!.collectionViewLayout = layout
    }


    // Delegate: Shotta
    func imagesDidUpdate(images: [[String: Any]]) {
        self.images = images
        self.collectionView?.reloadData()
    }

    // Delegate: ShottaUser
    func authenticationChanged(state: ShottaState) {
        if state == .authenticated {
            self.shottaUser?.loadImages()
        } else {
            setupShottaUser()
        }
    }

    // Delegate: UICollectionViewControllerDataSource

    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (images?.count)!
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! TileCell
        let imageParent = images![indexPath.row]
        let imageObject = imageParent["image"] as? [String: String]
        let imageUrl = imageObject?["url"]

        imageUrl?.fetchImage { (image, error, imageURL) in
            if error == nil {
                cell.imageView.image = image
            }
        }

        return cell
    }

    // Delegate: UIImagePickerController
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

// Extensions
public typealias ImageFetchCompletionClosure = (_ image: UIImage?, _ error: NSError?, _ imageURL: NSURL?) -> Void
extension String {
    func fetchImage(completionHandler: @escaping (_ image: UIImage?, _ error: NSError?, _ imageURL: NSURL?) -> Void) {
        if let imageURL = NSURL(string: self) {
            URLSession.shared.dataTask(with: imageURL as URL) { data, response, error in
                guard
                    let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let image = UIImage(data: data)
                    else {
                        if error != nil {
                            completionHandler(nil, error! as NSError, imageURL)
                        }
                        return
                }
                DispatchQueue.main.sync() { () -> Void in
                    completionHandler(image, nil, imageURL)
                }
            }.resume()
        }
    }
}

