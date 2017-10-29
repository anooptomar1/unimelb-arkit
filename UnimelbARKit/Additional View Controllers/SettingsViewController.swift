//
//  SettingsViewController
//  UnimelbARKit
//
//  Created by CHESDAMETREY on 22/9/17.
//  Copyright © 2017 com.chesdametrey. All rights reserved.
//

/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Popover view controller for app settings.
 */


import UIKit

enum Setting: String {
    case dragOnInfinitePlanes
    case debugVisual
    case focusSquare
    case measure
    case QRTracking
    case coreML
    case planeVisual
    
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Setting.dragOnInfinitePlanes.rawValue: true,
            Setting.debugVisual.rawValue: true,
            Setting.focusSquare.rawValue:true,
            Setting.measure.rawValue: false,
            Setting.QRTracking.rawValue: false,
            Setting.coreML.rawValue: false,
            Setting.planeVisual.rawValue: true
            ])
    }
}

extension UserDefaults {
    func bool(for setting: Setting) -> Bool {
        return bool(forKey: setting.rawValue)
    }
    func set(_ bool: Bool, for setting: Setting) {
        set(bool, forKey: setting.rawValue)
    }
}

class SettingsViewController: UITableViewController {
    
    // MARK: - UI Elements
    
    //@IBOutlet weak var scaleWithPinchGestureSwitch: UISwitch!
    @IBOutlet weak var dragOnInfinitePlanesSwitch: UISwitch!
    
    @IBOutlet weak var debugVisualSwitch: UISwitch!
    @IBOutlet weak var focusSquareSwitch: UISwitch!
    @IBOutlet weak var measureSwitch: UISwitch!
    @IBOutlet weak var QRTrackingSwitch: UISwitch!
    @IBOutlet weak var coreMLSwitch: UISwitch!
    @IBOutlet weak var planeVisualSwitch: UISwitch!
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let defaults = UserDefaults.standard
        // scaleWithPinchGestureSwitch.isOn = defaults.bool(for: .scaleWithPinchGesture)
        //dragOnInfinitePlanesSwitch.isOn = defaults.bool(for: .dragOnInfinitePlanes)
        debugVisualSwitch.isOn = defaults.bool(for: .debugVisual)
        focusSquareSwitch.isOn = defaults.bool(for: .focusSquare)
        measureSwitch.isOn = defaults.bool(for: .measure)
        QRTrackingSwitch.isOn = defaults.bool(for: .QRTracking)
        coreMLSwitch.isOn = defaults.bool(for: .coreML)
        planeVisualSwitch.isOn = defaults.bool(for: .planeVisual)
    }
    
    override func viewWillLayoutSubviews() {
        preferredContentSize.height = tableView.contentSize.height
    }
    
    // MARK: - Actions
    
    //  Created by CHESDAMETREY on 22/9/17.
    //  Copyright © 2017 com.chesdametrey. All rights reserved.
    @IBAction func didChangeSetting(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        switch sender {
            //case scaleWithPinchGestureSwitch:
            //    defaults.set(sender.isOn, for: .scaleWithPinchGesture)
            //case dragOnInfinitePlanesSwitch:
            //    defaults.set(sender.isOn, for: .dragOnInfinitePlanes)
            
            case debugVisualSwitch:
                defaults.set(sender.isOn, for: .debugVisual)
            case focusSquareSwitch:
                defaults.set(sender.isOn, for: .focusSquare)
            case QRTrackingSwitch:
                defaults.set(sender.isOn, for: .QRTracking)
            case planeVisualSwitch:
                defaults.set(sender.isOn, for: .planeVisual)
            
            // Setting coreML and Measure feature to not exist at the same time
            case coreMLSwitch:
                defaults.set(sender.isOn, for: .coreML)
                if coreMLSwitch.isOn{
                    measureSwitch.isOn = false
                    defaults.set(false, for: .measure)
                }
            case measureSwitch:
                defaults.set(sender.isOn, for: .measure)
                if measureSwitch.isOn{
                    coreMLSwitch.isOn = false
                    defaults.set(false, for: .coreML)
                }
            default: break
            }
    }
    
}
