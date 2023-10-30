//
//  Keyboard.swift
//  FireRTC
//
//  Created by young on 2023/10/23.
//

import Foundation
import UIKit

func getHeight(notification: NSNotification, view: UIView) -> CGFloat {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
        return keyboardSize.height - view.safeAreaInsets.bottom
    }
    return 0.0
}

func getHeight2(notification: NSNotification, view: UIView) -> CGFloat {
    guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return 0.0 }
    let keyboardScreenEndFrame = keyboardValue.cgRectValue
    let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
    print("Keyboard \(#function) height \(keyboardViewEndFrame.height)")
    print("Keyboard \(#function) bottom \(view.safeAreaInsets.bottom)")
    
    return keyboardViewEndFrame.height - view.safeAreaInsets.bottom
}

func moveView(view: UIView, y: CGFloat) {
    view.frame.origin.y -= y
//    self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 312, right: 0)
}
