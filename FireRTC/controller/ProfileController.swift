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
        
        tvName.text = user?.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    @IBAction func finish(_ sender: Any) {
        MoveTo.popController(ui: self)
    }
    
    @IBAction func startCall(_ sender: Any) {
        print("startCall")
        guard let controller = MoveTo.controller(ui: self, identifier: MoveTo.audioCallIdentifier) as? AudioCallController else {
            print("controller cast failure")
            return
        }
        controller.user = user
    }
    
    @IBAction func startVideo(_ sender: Any) {
        print("\(TAG) startVideo")
        guard let controller = MoveTo.controller(ui: self, identifier: MoveTo.videoCallIdentifier) as? VideoCallController else {
            print("controller cast failure")
            return
        }
        controller.user = user
    }
    
    @IBAction func startScreen(_ sender: Any) {
        print("\(TAG) startScreen")
        guard let controller = MoveTo.controller(ui: self, identifier: MoveTo.videoCallIdentifier) as? VideoCallController else {
            print("controller cast failure")
            return
        }
        controller.user = user
        controller.isScreen = true
    }
    
    @IBAction func startMessage(_ sender: Any) {
        MessageViewModel.instance.participant = user
        let _ = MoveTo.controller(ui: self, identifier: MoveTo.messageIdentifier)
    }
    
    @IBAction func test(_ sender: Any) {
        print("\(TAG) test")
        let _ = MoveTo.controller(ui: self, identifier: MoveTo.testIdentifier)
    }
}
