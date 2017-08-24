//
//  SettingsViewController.swift
//  Shotta
//
//  Created by Keaton Burleson on 8/24/17.
//  Copyright © 2017 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController{
    public var user: ShottaUser? = nil
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            // Logout
            if self.user != nil{
                self.user?.logout(completionHandler: { (state, error) in
                        self.dismiss(animated: true, completion: nil)
                
                })
            }
            break
        default:
            break
        }
    }
}
