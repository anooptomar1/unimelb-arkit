//
//  AlertViewController.swift
//  UnimelbARKit
//
//  Created by CHESDA on 20/8/17.
//  Copyright © 2017 com.chesdametrey. All rights reserved.
//

import Foundation
import UIKit

class AlertView{
    
    //MARK: - Show alert with the provided message and title
    func showAlertView(title: String, message: String) -> UIAlertController{
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}

