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
        
        tvName.text = user?.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("\(TAG) viewWillAppear")
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
        controller.user = self.user
    }
    
    @IBAction func test(_ sender: Any) {
        print("\(TAG) test")
        SendFCM.sendMessage(payload: SendFCM.getPayload(to: user!.fcmToken!, type: .Offer, callType: .AUDIO))
    }
}
