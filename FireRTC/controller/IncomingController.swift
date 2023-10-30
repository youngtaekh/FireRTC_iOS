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
    
    @IBOutlet weak var ivAnswer: UIButton!
    @IBOutlet weak var ivDecline: UIButton!
    
    @IBOutlet weak var ivAnswerHeight: NSLayoutConstraint!
    @IBOutlet weak var ivAnswerBottom: NSLayoutConstraint!
    
    var callVM = CallViewModel.instance
    var spaceId: String?
    var callType: Call.Category?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tvLabel.text = "Incoming \(callType!.rawValue)"
        callVM.controllerEvent = self
        
        if callType == .VIDEO {
            // Set button style as a default for setBackgroundImage programmatically
            ivAnswer.setBackgroundImage(UIImage(named: "round_videocam"), for: .normal)
            ivAnswerHeight.constant = 40.0
            ivAnswerBottom.constant = 75.0
        } else if callType == .SCREEN {
            ivAnswer.setBackgroundImage(UIImage(named: "round_mobile_screen_share"), for: .normal)
        }
    }
    
    @IBAction func answer(_ sender: Any) {
        MoveTo.popController(ui: self, action: true)
        if callType == .VIDEO || callType == .SCREEN {
            guard let controller = MoveTo.controller(ui: self, identifier: MoveTo.videoCallIdentifier) as? VideoCallController else {
                print("controller cast failure")
                return
            }
            controller.isOffer = false
            controller.isScreen = callType == .SCREEN
        } else {
            guard let controller = MoveTo.controller(ui: self, identifier: MoveTo.audioCallIdentifier) as? AudioCallController else {
                print("controller cast failure")
                return
            }
            controller.isOffer = false
        }
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
