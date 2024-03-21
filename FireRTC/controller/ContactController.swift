//
//  ContactController.swift
//  FireRTC
//
//  Created by young on 2023/07/20.
//

import UIKit
import FirebaseFirestore

class ContactController: UIViewController {
    private let TAG = "ContactController"

    @IBOutlet weak var tvEmpty: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
        tableView.delegate = self
        tableView.dataSource = self
        
        getContacts(source: .server)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("\(TAG) \(#function) \(UserRepository.contacts.isEmpty)")
        
        getContacts(source: .server)
    }
    
    func getContacts(source: FirestoreSource) {
        if (!SharedPreference.instance.getID().isEmpty) {
            print("\(TAG) getContacts")
            RelationRepository.getAll(source: source, reload: reload)
        }
    }
    
    func reload() {
        tvEmpty.isHidden = !UserRepository.contacts.isEmpty
        tableView.isHidden = UserRepository.contacts.isEmpty
        tableView.reloadData()
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

extension ContactController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserRepository.contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell", for: indexPath) as! ContactTableViewCell
        if (UserRepository.contacts.isEmpty) {
            cell.tvName.text = "Empty"
        } else {
            cell.tvName.text = UserRepository.contacts[indexPath[1]].name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //클릭한 셀의 이벤트 처리
        tableView.deselectRow(at: indexPath, animated: true)
        
        print("\(TAG) Click Cell Number: " + String(indexPath.row))
        print("\(TAG) Click Cell ID: " + UserRepository.contacts[indexPath.row].id)
        guard let controller = MoveTo.controller(ui: self, identifier: MoveTo.profileIdentifier) as? ProfileController else {
            print("\(TAG) parse controller failure")
            return
        }
        controller.user = UserRepository.contacts[indexPath.row]
    }
}
