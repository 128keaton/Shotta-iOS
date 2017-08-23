//
//  LoginViewController.swift
//  Shotta
//
//  Created by Keaton Burleson on 8/23/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController: UIViewController, ShottaUserDelegate{
    @IBOutlet var emailField: UITextField?
    @IBOutlet var passwordField: UITextField?
    let defaults = UserDefaults.standard
    fileprivate var temporaryUser: ShottaUser? = nil
    
    @IBAction func loginPressed(sender: UIButton){
         temporaryUser = ShottaUser(email: (self.emailField?.text)!, password: (self.passwordField?.text)!)
        temporaryUser?.delegate = self
    }
    
    func authenticationChanged(state: ShottaState) {
        if state == .authenticated{
            defaults.set(temporaryUser?.getAuthToken(), forKey: "auth-token")
            defaults.synchronize()

            NotificationCenter.default.post(name: Notification.Name(rawValue: "login-completed"), object: self)
                
            self.dismiss(animated: true, completion: nil)
            
        }
    }
    
}
