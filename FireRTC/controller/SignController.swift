//
//  SignController.swift
//  FireRTC
//
//  Created by young on 2023/07/18.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

class SignController: UIViewController, UITextFieldDelegate {
    private let TAG = "SignController"
    
    @IBOutlet weak var etId: UITextField!
    @IBOutlet weak var etPwd: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
        
        etId.placeholder = "ID"
        etPwd.placeholder = "Password"
        
        let sp = SharedPreference.instance
        etId.text = sp.getID()
        
        etId.delegate = self
        etId.tag = 0
        etId.returnKeyType = UIReturnKeyType.next
        etPwd.delegate = self
        etPwd.tag = 1
        etPwd.returnKeyType = UIReturnKeyType.done
        
//        etId.addDoneButtonOnKeyboard()
//        etPwd.addDoneButtonOnKeyboard()
    }
    
    @IBAction func start(_ sender: Any) {
        sign()
    }
    
    func sign() {
        if (!etId.text!.isEmpty && !etPwd.text!.isEmpty) {
            let id = etId.text!
            let lowerId = id.lowercased()
            let cryptoPwd = etPwd.text!.sha256()
            UserRepository.getUser(id: id) { result in
                switch result {
                    case .success(let user):
                        print(cryptoPwd)
                        print(user.password)
                        if cryptoPwd == user.password {
                            SharedPreference.instance.setID(id: lowerId)
                            SharedPreference.instance.setName(name: id)
                            SharedPreference.instance.setSign(value: true)
                            MoveTo.popController(ui: self)
                        } else {
                            print("Wrong Password!!!!!!!!!!~@!@!@")
                        }
                    case .failure(_):
                        let user = User(id: id, password: cryptoPwd, fcmToken: SharedPreference.instance.getFcmToken())
                        UserRepository.post(user: user) { err in
                            if let err = err {
                                print("\(self.TAG) Error writing user: \(err)")
                            } else {
                                SharedPreference.instance.setID(id: user.id)
                                SharedPreference.instance.setName(name: user.name)
                                SharedPreference.instance.setSign(value: true)
                                MoveTo.popController(ui: self)
                            }
                        }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
            print("done id")
        } else {
            textField.resignFirstResponder()
            print("done powd")
            sign()
            return true;
        }
        return false
    }
}

extension UITextField {
    @IBInspectable var doneAccessory: Bool {
        get {
            print("doneAccessory get")
            return self.doneAccessory
        }
        set (hasDone) {
            print("doneAccessory set \(hasDone)")
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    
    func addDoneButtonOnKeyboard() {
        print("addDoneButtonOnKeyboard")
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        print("doneButtonAction")
        self.resignFirstResponder()
    }
}
