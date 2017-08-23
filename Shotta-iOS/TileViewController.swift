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
        NotificationCenter.default.addObserver(self, selector: #selector(TileViewController.setupShottaUser), name: NSNotification.Name(rawValue: "login-completed"), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        setupShottaUser()
    }

    // Initializers
    @objc private func setupShottaUser() {
        let defaults = UserDefaults.standard
        if self.shottaUser == nil && defaults.object(forKey: "auth-token") != nil {
            self.shottaUser = ShottaUser(authToken: defaults.object(forKey: "auth-token") as! String)
            self.shottaUser?.setShottaDelegate(delegate: self)
            self.shottaUser?.delegate = self
        } else if self.shottaUser == nil && defaults.object(forKey: "auth-token") == nil {
            self.performSegue(withIdentifier: "showLogin", sender: self)
        } else if self.shottaUser != nil {
            self.shottaUser?.setShottaDelegate(delegate: self)
            self.shottaUser?.delegate = self
            self.shottaUser?.loadImages()
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

    func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        let collectionViewSize = collectionView?.frame.size

        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        let cellsPerRow: CGFloat = 3.0
        let itemSize = (collectionViewSize?.width)! / cellsPerRow

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

    // I am lazy
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: UITouch? = touches.first
        if touch?.view?.tag == 101 {
            touch?.view?.removeFromSuperview()
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

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageView = UIImageView(frame: collectionView.frame)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 101
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = UIColor.black

        let cell = self.collectionView?.cellForItem(at: indexPath) as! TileCell
        imageView.image = cell.imageView.image
        self.view.addSubview(imageView)
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

