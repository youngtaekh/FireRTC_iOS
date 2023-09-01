//
//  IncomingController.swift
//  FireRTC
//
//  Created by young on 2023/08/22.
//

import UIKit

class IncomingController: UIViewController {
    private let TAG = "IncomingController"
    
    @IBOutlet weak var tvLabel: UILabel!
    
    var callVM = CallViewModel.instance
    var spaceId: String?
    var callType: Call.Category?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tvLabel.text = "Incoming \(String(describing: callType?.rawValue))"
        callVM.controllerEvent = self
    }
    
    @IBAction func answer(_ sender: Any) {
        MoveTo.popController(ui: self, action: true)
        guard let controller = MoveTo.controller(ui: self, identifier: MoveTo.audioCallIdentifier) as? AudioCallController else {
            print("controller cast failure")
            return
        }
        controller.isOffer = false
    }
    
    @IBAction func decline(_ sender: Any) {
        callVM.endCall(type: .Decline)
    }
}

extension IncomingController: ControllerEvent {
    func onTerminatedCall() {
        print("\(TAG) onTerminatedCall")
        MoveTo.popController(ui: self, action: true)
    }
    
    func onPCConnected() {
        print("\(TAG) onPConnected")
    }
}
