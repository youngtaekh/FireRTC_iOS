//
//  MessageViewModel.swift
//  FireRTC
//
//  Created by young on 2023/09/01.
//

import Foundation
import WebRTC

class MessageViewModel {
    private let TAG = "MessageViewModel"
    static var instance = MessageViewModel()
    
    var chat: Chat? = nil
    var messageMap = [String: [Message]]()
    var participant: User!
    var messageList: [Message] {
        get {
            return (self.chat == nil || messageMap[self.chat!.id] == nil) ? [Message]() : messageMap[self.chat!.id]!
        }
    }
    
    var rtpManager = RTPManager()
    var isOffer = true
    var isConnected = false
    var isTerminated = false
    var remoteSDP: String? = nil
    
    var controllerEvent: ControllerEvent?
    var messageEvent: MessageEvent?
}

extension MessageViewModel {
    func release() {
        self.rtpManager.release()
        self.rtpManager = RTPManager()
        
        self.remoteSDP = nil
    }
    
    func start(completion: @escaping () -> Void) {
        self.isOffer = true
        var ids = [String]()
        ids.append(participant.id)
        ids.append(SharedPreference.instance.getID())
        ids.sort()
        self.chat = Chat(title: participant.name, participants: ids)
        getChat(id: self.chat!.id) {
            self.rtpManager.start(isDataChannel: true, isOffer: self.isOffer, rtpListener: self)
            completion()
        }
    }
    
    func addRemoteCandidate(sdp: String) {
        print("\(TAG) \(#function)")
        rtpManager.addRemoteCandidate(sdp: sdp)
    }
    
    func answerCall() {
        rtpManager.start(isDataChannel: true, isOffer: false, remoteSDP: self.remoteSDP, rtpListener: self)
    }
    
    func endCall(type: SendFCM.FCMType = .Bye) {
        SendFCM.sendMessage(payload: SendFCM.getPayload(to: participant.fcmToken!, type: type, callType: .MESSAGE))
        onTerminatedCall()
    }
    
    func sendData(msg: String) {
        let message = Message(chatId: self.chat!.id, body: msg)
        message.createdAt = Date.now
        print("\(TAG) chatId \(self.chat!.id)")
        self.messageMap[self.chat!.id]?.append(message)
        if (!isTerminated && isConnected) {
            rtpManager.sendData(msg: msg)
        }
    }
    
    func onIncomingCall(userId: String?, chatId: String?, message: String?, sdp: String?, fcmToken: String?) {
        print("onIncomingCall userId \(userId!), chatId \(chatId != nil), message \(message != nil), sdp \(sdp != nil), fcmToken \(fcmToken != nil)")
        if (chatId == nil || userId == nil) { return }
        if (chat == nil || chat!.id != chatId) {
            getUser(id: userId!) {
                SendFCM.sendMessage(payload: SendFCM.getPayload(to: fcmToken!, type: .Decline, callType: .MESSAGE, targetOS: self.participant.os))
            }
            return
        }
        
        self.isOffer = false
        self.remoteSDP = sdp
        getChat(id: chatId!) {
            self.rtpManager.start(isDataChannel: true, isOffer: false, remoteSDP: self.remoteSDP, rtpListener: self)
        }
    }
    
    func onAnswerCall(sdp: String?) {
        print("\(TAG) \(#function) sdp \(sdp != nil)")
        if sdp != nil {
            rtpManager.setRemoteDescription(isOffer: false, sdp: sdp!)
        }
    }
    
    func onTerminatedCall() {
        release()
        controllerEvent?.onTerminatedCall()
    }
    
//    let task = DispatchWorkItem {
//        print("DispatchWorkItem")
//    }
}

extension MessageViewModel {
    private func getChat(id: String, handler: (() -> Void)? = nil) {
        ChatRepository.getChat(id: id) { result in
            switch result {
                case .success(let chat):
                    print("getChat success \(chat)")
                    self.chat = chat
                    self.messageMap[chat.id] = [Message]()
                    if handler != nil {
                        handler!()
                    }
                case.failure(let err):
                    print("getChat failure \(err)")
                    self.postChat(handler: handler)
                    
            }
        }
    }
    
    private func postChat(handler: (() -> Void)? = nil) {
        ChatRepository.post(chat: self.chat!) { err in
            if let err = err {
                print("\(self.TAG) chat post error \(err)")
            } else {
                if handler != nil {
                    handler!()
                }
            }
        }
    }
    
    private func getUser(id: String, handler: (() -> Void)? = nil) {
        UserRepository.getUser(id: id) { result in
            switch result {
                case .success(let user):
                    print("\(self.TAG) getUser Success")
                    self.participant = user
                    if handler != nil {
                        handler!()
                    }
                case .failure(let err):
                    print("\(self.TAG) getUser error \(err)")
            }
        }
    }
}

extension MessageViewModel: RTPListener {
    func onDescriptionSuccess(type: Int, sdp: String) {
        print("\(TAG) \(#function)")
        let fcmType: SendFCM.FCMType = isOffer ? .Offer : .Answer
        SendFCM.sendMessage(payload: SendFCM.getPayload(to: participant.fcmToken!, type: fcmType, callType: .MESSAGE, chatId: self.chat!.id, sdp: sdp))
    }
    
    func onIceCandidate(candidate: String) {
        print("\(TAG) \(#function)")
        SendFCM.sendMessage(payload: SendFCM.getPayload(to: participant.fcmToken!, type: .Ice, callType: .MESSAGE, chatId: chat!.id, sdp: candidate))
    }
    
    func onPCConnected() {
        print("\(TAG) \(#function)")
        isConnected = true
        isTerminated = false
        controllerEvent?.onPCConnected()
    }
    
    func onPCDisconnected() {
        print("\(TAG) \(#function)")
    }
    
    func onPCFailed() {
        print("\(TAG) \(#function)")
    }
    
    func onPCClosed() {
        print("\(TAG) \(#function)")
        isTerminated = true
    }
    
    func onPCError(description: String?) {
        print("\(TAG) \(#function)")
    }
    
    func onMessage(message: String) {
        print("\(TAG) \(#function)")
        let msg = Message(from: participant.id, chatId: self.chat!.id, body: message)
        msg.createdAt = Date.now
        print("\(TAG) chatId \(self.chat!.id)")
        self.messageMap[self.chat!.id]?.append(msg)
        messageEvent?.onMessageReceived(msg: message)
    }
    
    func onLocalVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) \(#function)")
    }
    
    func onRemoteVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onRemoteVideoTrack")
    }
}

protocol MessageEvent {
    func onMessageReceived(msg: String)
}
