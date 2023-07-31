//
//  ProfileController.swift
//  FireRTC
//
//  Created by young on 2023/07/18.
//

import UIKit

class AddContactController: UIViewController, UITextFieldDelegate {
    private let TAG = "AddContactController"
    
    @IBOutlet weak var searchId: UITextField!
    
    @IBOutlet weak var ivProfile: UIImageView!
    
    @IBOutlet weak var tvName: UILabel!
    
    @IBOutlet weak var tvAdd: UIButton!
    
    private var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self

        searchId.delegate = self
        searchId.tag = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }

    @IBAction func finish(_ sender: Any) {
        MoveTo.popController(ui: self)
    }
    
    @IBAction func addContact(_ sender: Any) {
        view.endEditing(true)
        let relation = Relation(
            from: SharedPreference.instance.getID(),
            to: user!.id
        )
        RelationRepository.post(relation: relation) { err in
            if let err = err {
                print("\(self.TAG) Error writing document: \(err)")
            } else {
                self.tvAdd.isHidden = true
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        print("clear")
        view.endEditing(true)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("search")
        let id = textField.text
        if (id != nil && !id!.isEmpty) {
            if id! == SharedPreference.instance.getID() {
                self.tvName.isHidden = false
                self.tvName.text = "My Id error"
            } else {
                UserRepository.getUser(id: id!) { result in
                    switch result {
                        case .success(let user):
                            self.user = user
                            self.ivProfile.isHidden = false
                            self.tvName.isHidden = false
                            self.tvAdd.isHidden = false
                            self.tvName.text = user.name
                        case .failure(_):
                            self.ivProfile.isHidden = true
                            self.tvName.isHidden = false
                            self.tvAdd.isHidden = true
                            self.tvName.text = "No Search Error"
                    }
                }
            }
        }
        return false
    }
}

extension AddContactController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


