//
//  CallViewModel.swift
//  FireRTC
//
//  Created by young on 2023/08/17.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import WebRTC

class CallViewModel {
    private let TAG = "CallViewModel"
    static var instance = CallViewModel()
    
    var space: Space?
    var call: Call!
    var counterpart: User!
    var rtpManager = RTPManager()
    var isOffer = true
    var remoteSDP: String? = nil
    
    var controllerEvent: ControllerEvent!
    var videoEvent: VideoEvent!
    
    private init() {}
}

extension CallViewModel {
    
    func release() {
        self.space = nil
        rtpManager.release()
        rtpManager = RTPManager()
        
        self.remoteSDP = nil
    }
    
    func startCall(callType: Call.Category, counterpart: User) {
        self.isOffer = true
        self.space = Space(callType: callType)
        self.call = Call(spaceId: self.space!.id, counterpartName: counterpart.name, type: callType, direction: .Offer)
        self.counterpart = counterpart
        self.space?.calls.append(self.call.id)
        postSpace()
        postCall()
        rtpManager.start(
            isAudio: callType != .MESSAGE,
            isVideo: callType == .VIDEO || callType == .SCREEN,
            isScreen: callType == .SCREEN,
            isDataChannel: callType == .MESSAGE,
            isOffer: true,
            rtpListener: self
        )
    }
    
    func addRemoteCandidate(sdp: String) {
        rtpManager.addRemoteCandidate(sdp: sdp)
    }
    
    func answerCall() {
        rtpManager.start(
            isAudio: self.call.type != .MESSAGE,
            isVideo: self.call.type == .VIDEO || self.call.type == .SCREEN,
            isScreen: self.call.type == .SCREEN,
            isDataChannel: self.call.type == .MESSAGE,
            isOffer: false,
            remoteSDP: self.remoteSDP,
            rtpListener: self)
    }
    
    func busy() {
        endCall(type: .Busy)
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
        self.call = Call(
            spaceId: spaceId,
            type: Call.Category.init(rawValue: type)!,
            direction: .Answer
        )
        getSpace(id: spaceId) {
            self.updateCallList()
            self.updateParticipantList()
        }
        getUser(id: counterpartId) {
            self.call!.counterpartName = self.counterpart!.name
            self.postCall() {
                MoveTo.toIncomingCallVC(spaceId: spaceId, callType: self.call.type)
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
    
    func startCapture(isBack: Bool) {
        print("\(TAG) \(#function)")
        rtpManager.startCapture(isBack: isBack)
    }
    
    func stopCapture() {
        print("\(TAG) \(#function)")
        rtpManager.stopCapture()
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
    
    private func postCall(handler: (() -> Void)? = nil) {
        CallRepository.post(call: call!) { err in
            if let err = err {
                print("\(self.TAG) call post error \(err)")
            } else {
                if (handler != nil) {
                    handler!()
                }
            }
        }
    }
    
    private func updateCall(map: [String: Any]) {
        CallRepository.update(id: call.id, map: map) { err in
            if let error = err {
                print("\(self.TAG) call update error \(error)")
            }
        }
    }
    
    private func updateCallList() {
        SpaceRepository.addCallList(spaceId: space!.id, callId: call!.id)
    }
    
    private func updateParticipantList() {
        SpaceRepository.addParticipantList(spaceId: space!.id)
    }
    
    private func getUser(id: String, handler: @escaping () -> Void) {
        UserRepository.getUser(id: id) { result in
            switch result {
                case .success(let user):
                    self.counterpart = user
                    handler()
                case .failure(let err):
                    print("\(self.TAG) getUser Failure \(err)")
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
        var map = [String: Any]()
        map[CONNECTED] = true
        map[CONNECTED_AT] = FieldValue.serverTimestamp()
        updateCall(map: map)
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
    
    func onLocalVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onLocalVideoTrack")
        videoEvent.onLocalVideoTrack(track: track)
    }
    
    func onRemoteVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onRemoteVideoTrack")
        videoEvent.onRemoteVideoTrack(track: track)
    }
}

protocol ControllerEvent {
    func onTerminatedCall()
    func onPCConnected()
}

protocol VideoEvent {
    func onLocalVideoTrack(track: RTCVideoTrack)
    func onRemoteVideoTrack(track: RTCVideoTrack)
}
