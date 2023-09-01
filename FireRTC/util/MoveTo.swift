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
    
    static func topMostController() -> UIViewController {
//        var topController: UIViewController
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        let windowScene = scene as! UIWindowScene
        var topController: UIViewController = windowScene.keyWindow!.rootViewController!
        
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    static func toIncomingCallVC(spaceId: String, callType: Call.Category) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "viewController")
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        if let windowScene = scene as? UIWindowScene {
            let navigationController = windowScene.keyWindow?.rootViewController as! UINavigationController
            let incomingController = storyboard.instantiateViewController(withIdentifier: "incomingVC") as! IncomingController
            incomingController.spaceId = spaceId
            incomingController.callType = callType
            navigationController.interactivePopGestureRecognizer?.isEnabled = false
            navigationController.isNavigationBarHidden = true
            navigationController.pushViewController(incomingController, animated: true)
        }
        
//        let topVC = topMostController()
//        let incomingController = storyboard.instantiateViewController(withIdentifier: "incomingVC") as! IncomingController
//        incomingController.spaceId = spaceId
//        incomingController.callType = callType
//        topVC.present(incomingController, animated: true, completion: nil)
    }
}
