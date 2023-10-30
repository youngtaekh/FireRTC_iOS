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
    @IBOutlet weak var tvTime: UILabel!
    @IBOutlet weak var tvMute: UIButton!
    
    var user: User!
    
    var startTime = Date().timeIntervalSince1970
    var timer: Timer?
    
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
        tvTime.text = isOffer ? "Calling..." : ""
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
    
    private func parseTime(time: Int) {
        if time >= 3600 {
            let hour = time / 3600
            let min = (time % 3600) / 60
            let sec = time % 60
            tvTime.text = String(format: "(%02d : %02d : %02d)", hour, min, sec)
        } else {
            let min = time / 60
            let sec = time % 60
            tvTime.text = String(format: "(%02d : %02d)", min, sec)
        }
    }
}

extension AudioCallController: ControllerEvent {
    func onTerminatedCall() {
        print("\(TAG) onTerminatedCall")
        MoveTo.popController(ui: self, action: true)
        timer?.invalidate()
    }
    
    func onPCConnected() {
        print("\(TAG) onPCConnected")
        startTime = Date().timeIntervalSince1970
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { timer in
                let time = Int(Date().timeIntervalSince1970 - self.startTime)
                self.parseTime(time: time)
            })
        }
    }
}
