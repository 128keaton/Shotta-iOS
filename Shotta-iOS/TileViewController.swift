//
//  TileViewController.swift
//  Shotta
//
//  Created by Keaton Burleson on 8/23/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Agrume

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
        let stack = navigationController?.viewControllers
        navigationController?.popToViewController(stack![0], animated: true)
        
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


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSettings"{
            let settingsViewController = segue.destination as! SettingsViewController
            settingsViewController.user = self.shottaUser
        }
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
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "auth-token")
            defaults.synchronize()
            self.shottaUser = nil
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

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! TileCell
        let image = cell.imageView.image
        let agrume = Agrume(image: image!, backgroundBlurStyle: .dark)
        
        let imageParent = images![indexPath.row]
        let imageId = "\(String(describing: imageParent["id"]))"

        agrume.metadata = [0: ["url": "http://shotta.128keaton.com/view/\(imageId)"]]
        
        agrume.didTapActivityButton = { image, metadata in
            #if DEBUG
                print(metadata ?? "No metadata")
            #endif
            self.displayShareSheet(items: [image, URL(string: metadata!["url"] as! String)!], onView: agrume)
        }
        agrume.useToolbar = true
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self.parent!, backgroundSnapshotVC: self.parent)
    }

    func displayShareSheet(items: [ Any], onView: UIViewController){
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        onView.present(activityViewController, animated: true, completion: {})
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

