//
//  CallViewModel.swift
//  FireRTC
//
//  Created by young on 2023/08/17.
//

import Foundation
import FirebaseFirestoreSwift

class CallViewModel {
    private let TAG = "CallViewModel"
    static var instance = CallViewModel()
    
    var space: Space?
    var call: Call!
    var counterpart: User!
    var rtpManager = RTPManager()
    var isOffer = true
    var remoteSDP: String? = nil
    var remoteICE = [String]()
    
    var controllerEvent: ControllerEvent!
    
    private init() {}
}

extension CallViewModel {
    
    func release() {
        self.space = nil
        rtpManager.release()
        rtpManager = RTPManager()
        
        self.remoteSDP = nil
        self.remoteICE = [String]()
    }
    
    func startCall(callType: Call.Category, counterpart: User) {
        self.isOffer = true
        self.space = Space(callType: callType)
        self.call = Call(spaceId: self.space!.id, type: callType, direction: .Offer)
        self.counterpart = counterpart
        self.space?.calls.append(self.call.id)
        postSpace()
        postCall() {
            self.rtpManager.start(
                isAudio: callType == .AUDIO,
                isVideo: callType == .VIDEO || callType == .SCREEN,
                isScreen: callType == .SCREEN,
                isOffer: true,
                rtpListener: self
            )
        }
    }
    
    func addRemoteCandidate(sdp: String) {
        remoteICE.append(sdp)
        rtpManager.addRemoteCandidate(sdp: sdp)
    }
    
    func answerCall() {
        rtpManager.start(
            isAudio: self.call.type == .AUDIO,
            isVideo: self.call.type == .VIDEO || self.call.type == .SCREEN,
            isScreen: self.call.type == .SCREEN,
            isOffer: false,
            remoteSDP: self.remoteSDP,
            rtpListener: self)
    }
    
    func endCall(type: SendFCM.FCMType = .Bye) {
        space!.terminated = true
        SpaceRepository.updateStatus(space: space!, reason: type.rawValue) { err in
            if let err = err {
                print("\(self.TAG) space update status error \(err)")
            }
        }
        // TODO: send fcm
        if (counterpart != nil && counterpart!.fcmToken != nil) {
            SendFCM.sendMessage(payload: SendFCM.getPayload(to: counterpart!.fcmToken!, type: type, callType: call!.type, spaceId: space!.id, callId: call!.id))
        }
        
        onTerminatedCall()
    }
    
    func onIncomingCall(spaceId: String, type: String, counterpartId: String, fcmToken: String, remoteSDP: String) {
        self.isOffer = false
        self.remoteSDP = remoteSDP
        let isBusy = self.space != nil
        self.call = Call(
            spaceId: spaceId,
            type: Call.Category.init(rawValue: type)!,
            direction: .Answer
        )
        getSpace(id: spaceId) {
            self.updateCallList()
            self.updateParticipantList()
        }
        postCall() {
            if (isBusy) {
                self.endCall(type: .Busy)
            } else {
                self.getUser(id: counterpartId) {
                    MoveTo.toIncomingCallVC(spaceId: spaceId, callType: self.call.type)
                }
            }
        }
    }
    
    func onAnswerCall(isOffer: Bool, sdp: String) {
        self.space?.connected = true
        SpaceRepository.update(id: self.space!.id, map: [CONNECTED: true])
        self.remoteSDP = sdp
        rtpManager.setRemoteDescription(isOffer: isOffer, sdp: sdp)
    }
    
    func onTerminatedCall() {
        if space != nil {
            space!.leaves.append(SharedPreference.instance.getID())
            SpaceRepository.addLeaveList(spaceId: space!.id, participantId: SharedPreference.instance.getID()) {
                (err) in
                
                if let err = err {
                    print("\(self.TAG) addLeaveList error \(err)")
                }
            }
        }
        if call != nil {
            call!.terminated = true
            CallRepository.updateTerminatedAt(id: call!.id) {
                (err) in
                
                if let err = err {
                    print("\(self.TAG) call updateTerminatedAt \(err)")
                }
            }
        }
        release()
        controllerEvent.onTerminatedCall()
    }
    
    func mute() {
        rtpManager.muteAudio()
    }
    
    func unmute() {
        rtpManager.unmuteAudio()
    }
}

//Database
extension CallViewModel {
    
    private func postSpace(handler: (() -> Void)? = nil) {
        SpaceRepository.post(space: space!) { err in
            if let err = err {
                print("\(self.TAG) space post error \(err)")
            } else {
                if (handler != nil) {
                    handler!()
                }
            }
        }
    }
    
    private func getSpace(id: String, handler: @escaping () -> Void) {
        SpaceRepository.getSpace(id: id) { result in
            switch result {
                case .success(let space):
                    self.space = space
                    handler()
                case .failure(let err):
                    print("\(self.TAG) getSpace error: \(err)")
            }
        }
    }
    
    private func postCall(handler: @escaping () -> Void) {
        CallRepository.post(call: call!) { err in
            if let err = err {
                print("\(self.TAG) call post error \(err)")
            } else {
                handler()
            }
        }
    }
    
    private func updateCallList() {
        SpaceRepository.addCallList(spaceId: space!.id, callId: call!.id) { err in
            if let err = err {
                print("\(self.TAG) addCallList Error \(err)")
            }
        }
    }
    
    private func updateParticipantList() {
        SpaceRepository.addParticipantList(spaceId: space!.id) { err in
            if let err = err {
                print("\(self.TAG) addParticipant Error \(err)")
            }
        }
    }
    
    private func getUser(id: String, handler: @escaping () -> Void) {
        UserRepository.getUser(id: id) { result in
            switch (result) {
                case .success(let counterpart):
                    self.counterpart = counterpart
                    handler()
                case .failure(let err):
                    print("getUser failure \(err)")
            }
        }
    }
}

extension CallViewModel: RTPListener {
    func onDescriptionSuccess(type: Int, sdp: String) {
        print("\(self.TAG) description type \(type)")
        print("\(self.TAG) description sdp \(sdp)")
        if (counterpart != nil && counterpart!.fcmToken != nil) {
            self.call.sdp = sdp
            CallRepository.updateSDP(call: self.call)
            let fcmType: SendFCM.FCMType = isOffer ? .Offer : .Answer
            SendFCM.sendMessage(payload: SendFCM.getPayload(to: counterpart!.fcmToken!, type: fcmType, callType: call!.type, spaceId: space!.id, callId: call!.id, sdp: sdp))
        }
    }
    
    func onIceCandidate(candidate: String) {
        print("\(self.TAG) onIceCandidate \(candidate)")
        if (counterpart != nil && counterpart!.fcmToken != nil) {
            CallRepository.updateCandidate(id: self.call.id, candidate: candidate)
            SendFCM.sendMessage(payload: SendFCM.getPayload(to: counterpart!.fcmToken!, type: .Ice, callType: call!.type, spaceId: space!.id, callId: call!.id, sdp: candidate))
        }
    }
    
    func onPCConnected() {
        print("\(self.TAG) onPCConnected")
        controllerEvent.onPCConnected()
    }
    
    func onPCDisconnected() {
        print("\(self.TAG) onPCDisconnected")
    }
    
    func onPCFailed() {
        print("\(self.TAG) onPCFailed")
    }
    
    func onPCClosed() {
        print("\(self.TAG) onPCClosed")
    }
    
    func onPCError(description: String?) {
        print("\(self.TAG) onPCError")
    }
    
    func onMessage(message: String) {
        print("\(self.TAG) onMessage \(message)")
    }
}

protocol ControllerEvent {
    func onTerminatedCall()
    func onPCConnected()
}
