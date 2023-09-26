//
//  TestController.swift
//  FireRTC
//
//  Created by young on 2023/09/21.
//

import UIKit

class TestController: UIViewController {
    private let TAG = "TestController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TestController viewDidLoad")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        print("\(TAG) \(#function) height \(keyboardViewEndFrame.height)")
        print("\(TAG) \(#function) bottom \(view.safeAreaInsets.bottom)")
        
//        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
//        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
//        let selectedRange = self.scrollView.selectedRange
//        self.scrollView.scrollRangeToVisible(selectedRange)
        
//        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            print("\(TAG) \(#function) keyboardSize \(keyboardSize.height)")
//            self.bottomView.frame.origin.y -= keyboardSize.height - view.safeAreaInsets.bottom
//        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("\(TAG) \(#function)")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
