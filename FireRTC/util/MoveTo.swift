//
//  MoveTo.swift
//  FireRTC
//
//  Created by young on 2023/07/24.
//

import Foundation
import UIKit

class MoveTo {
    static let signIdentifier = "signVC"
    static let addContactIdentifier = "addContactVC"
    static let profileIdentifier = "profileVC"
    static let audioCallIdentifier = "audioCallVC"
    
    static func modal(ui: UIViewController, identifier: String) -> UIViewController {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: identifier)
        controller.modalTransitionStyle = .coverVertical
        ui.present(controller, animated: true, completion: nil)
        return controller
    }
    
    static func controller(ui: UIViewController, identifier: String, action: Bool = false) -> UIViewController {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyBoard.instantiateViewController(withIdentifier: identifier)
        ui.navigationController?.interactivePopGestureRecognizer?.isEnabled = action
        ui.navigationController?.isNavigationBarHidden = !action
        ui.navigationController?.pushViewController(controller, animated: true)
        return controller
    }
    
    static func popController(ui: UIViewController, action: Bool = true) {
        ui.navigationController?.interactivePopGestureRecognizer?.isEnabled = action
        ui.navigationController?.isNavigationBarHidden = !action
        ui.navigationController?.popViewController(animated: true)
    }
    
    static func test(ui: UIViewController, identifier: String) {
        let vcToPresent = ui.storyboard!.instantiateViewController(withIdentifier: identifier) as! SignController
        ui.present(vcToPresent, animated: true, completion: nil)
    }
}
