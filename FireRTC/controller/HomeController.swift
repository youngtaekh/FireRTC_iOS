//
//  HomeController.swift
//  FireRTC
//
//  Created by young on 2023/07/18.
//

import UIKit

class HomeController: UITabBarController {
    private let TAG = "HomeController"
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var ivAddContact: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("\(TAG) \(#function)")
//        ivAddContact.frame = CGRectMake(-100, -100, 0, 0)
//        navigationBar.title = "Title"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("\(TAG) \(#function)")
        
        let sp = SharedPreference.instance
        if (!sp.isSign()) {
            let _ = MoveTo.controller(ui: self, identifier: MoveTo.signIdentifier)
        }
        let tabIndex = sp.getTabIndex()
        selectedIndex = tabIndex
        if (tabIndex == 0) {
            ivAddContact.isHidden = false
            navigationBar.title = "Contacts"
        } else if (tabIndex == 1) {
            ivAddContact.isHidden = true
            navigationBar.title = "History"
        } else {
            ivAddContact.isHidden = true
            navigationBar.title = "Settings"
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if (tabBar.items != nil) {
            let sp = SharedPreference.instance
            if (tabBar.items!.firstIndex(of: item) == 0) {
                ivAddContact.isHidden = false
                navigationBar.title = "Contacts"
                sp.setTabIndex(value: 0)
            } else if (tabBar.items!.firstIndex(of: item) == 1) {
                ivAddContact.isHidden = true
                navigationBar.title = "History"
                sp.setTabIndex(value: 1)
            } else {
                ivAddContact.isHidden = true
                navigationBar.title = "Settings"
                sp.setTabIndex(value: 2)
            }
        } else {
            ivAddContact.isHidden = true
        }
    }
    
    @IBAction func addContact(_ sender: Any) {
        print("\(TAG) \(#function)")
        let _ = MoveTo.controller(ui: self, identifier: MoveTo.addContactIdentifier, action: true)
    }
    
    func add() {
        guard let controller = self.selectedViewController as? ContactController else {
            return
        }
        UserRepository.contacts.append(User(id: "TestID", password: "aaa"))
        controller.tableView.reloadData()
    }
}
