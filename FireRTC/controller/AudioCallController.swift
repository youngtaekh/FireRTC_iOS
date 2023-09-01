//
//  AudioCallController.swift
//  FireRTC
//
//  Created by young on 2023/08/09.
//

import UIKit

class AudioCallController: UIViewController {
    private let TAG = "AudioCallController"
    
    let callVM = CallViewModel.instance
    var isOffer: Bool = true
    var isMute = false

    @IBOutlet weak var tvName: UILabel!
    @IBOutlet weak var tvMute: UIButton!
    
    var user: User!
    
    let rtpManager = RTPManager()
    
    var terminated: Bool? {
        didSet {
            print("terminated didSet")
            MoveTo.popController(ui: self, action: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(TAG) viewDidLoad")
        
        callVM.controllerEvent = self
        if (isOffer) {
            callVM.counterpart = user
            callVM.startCall(callType: .AUDIO, counterpart: user!)
        } else {
            user = callVM.counterpart
            callVM.answerCall()
        }
        
        tvName.text = user?.name
    }
    
    @IBAction func mute(_ sender: Any) {
        if (isMute) {
            callVM.unmute()
        } else {
            callVM.mute()
        }
        isMute = !isMute
    }
    
    @IBAction func end(_ sender: Any) {
        print("\(TAG) end")
        callVM.endCall()
    }
}

extension AudioCallController: ControllerEvent {
    func onTerminatedCall() {
        print("\(TAG) onTerminatedCall")
        MoveTo.popController(ui: self, action: true)
    }
    
    func onPCConnected() {
        print("\(TAG) onPCConnected")
    }
}
