//
//  AudioCallController.swift
//  FireRTC
//
//  Created by young on 2023/08/09.
//

import UIKit

class AudioCallController: UIViewController {
    private let TAG = "AudioCallController"

    @IBOutlet weak var tvName: UILabel!
    var user: User?
    var space: Space?
    var call: Call?
    
    let rtpManager = RTPManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("\(TAG) viewDidLoad")
        // Do any additional setup after loading the view.
        
        tvName.text = user?.name
        
        rtpManager.initialize()
        rtpManager.startRTP(isOffer: true, remoteSDP: nil)
    }
    
    @IBAction func end(_ sender: Any) {
        print("\(TAG) end")
        rtpManager.release()
        MoveTo.popController(ui: self, action: true)
    }
    
    private func createSpace() {
        space = Space(callType: .AUDIO)
        SpaceRepository.post(space: space!) { err in
            if let err = err {
                print("\(self.TAG) space post \(err)")
            } else {
                self.createCall(spaceId: self.space!.id)
            }
        }
    }
    
    private func createCall(spaceId: String) {
        call = Call(spaceId: spaceId, counterpartName: user!.name)
        CallRepository.post(call: call!) { err in
            if let err = err {
                print("\(self.TAG) createCall error \(err)")
            }
        }
    }
    
    private func endCall() {
        space!.terminated = true
        SpaceRepository.updateStatus(space: space!) { err in
            if let err = err {
                print("\(self.TAG) updateStatus error \(err)")
            }
        }
        // TODO: send fcm
        onTerminatedCall()
    }
    
    func onTerminatedCall() {
        if (space != nil) {
            space!.leaves.append(SharedPreference.instance.getID())
            SpaceRepository.addLeaveList(spaceId: space!.id, participantId: SharedPreference.instance.getID()) { err in
                if let err = err {
                    print("\(self.TAG) addLeaveList error \(err)")
                }
            }
        }
        if call != nil {
            call!.terminated = true
            CallRepository.updateTerminatedAt(id: call!.id) { err in
                if let err = err {
                    print("\(self.TAG) call updateTerminatedAt \(err)")
                }
            }
        }
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
