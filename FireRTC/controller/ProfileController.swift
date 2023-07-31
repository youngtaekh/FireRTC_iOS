//
//  ProfileController.swift
//  FireRTC
//
//  Created by young on 2023/07/27.
//

import UIKit

class ProfileController: UIViewController {
    private let TAG = "ProfileController"
    
    var user: User?
    @IBOutlet weak var tvName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\(TAG) \(#function)")
        print("selected user \(String(describing: user?.toString()))")
        
        tvName.text = user?.name

        // Do any additional setup after loading the view.
    }
    
    @IBAction func finish(_ sender: Any) {
        MoveTo.popController(ui: self)
    }
    
    @IBAction func startCall(_ sender: Any) {
        print("startCall")
    }
    
    @IBAction func test(_ sender: Any) {
        print("selected user \(String(describing: user?.toString()))")
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
