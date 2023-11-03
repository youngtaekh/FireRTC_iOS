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
            return (chat == nil || messageMap[chat!.id] == nil) ? [Message]() : messageMap[chat!.id]!
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
        rtpManager.release()
        rtpManager = RTPManager()
        
        isConnected = false
        isTerminated = false
        remoteSDP = nil
    }
    
    func start(completion: (() -> Void)?) {
        isOffer = true
        var ids = [String]()
        ids.append(participant.id)
        ids.append(SharedPreference.instance.getID())
        ids.sort()
        chat = Chat(title: participant.name, participants: ids)
        getChat(id: chat!.id) {
            completion?()
        }
    }
    
    func addRemoteCandidate(sdp: String) {
        print("\(TAG) \(#function)")
        rtpManager.addRemoteCandidate(sdp: sdp)
    }
    
    func sendCall() {
        isOffer = true
        rtpManager.start(isDataChannel: true, isOffer: true, rtpListener: self)
    }
    
    func answerCall() {
        rtpManager.start(isDataChannel: true, isOffer: false, remoteSDP: remoteSDP, rtpListener: self)
    }
    
    func endCall(type: SendFCM.FCMType = .Bye) {
        if isConnected {
            SendFCM.sendMessage(
                payload: SendFCM.getPayload(
                    to: participant.fcmToken!,
                    type: type,
                    callType: .MESSAGE,
                    chatId: chat!.id,
                    targetOS: participant.os
                )
            )
        }
        onTerminatedCall()
    }

    func sendData(msg: String) {
        let message = Message(chatId: chat!.id, body: msg)
        message.createdAt = Date.now
        print("\(TAG) chatId \(chat!.id)")
        if messageMap[chat!.id] == nil {
            print("\(TAG) \(#function) messageList reset \(chat!.title)")
            messageMap[chat!.id] = [Message]()
        }
        addDateView(message: message)

        messageMap[chat!.id]?.insert(message, at: 0)
        if isConnected {
            rtpManager.sendData(msg: msg)
        } else {
            SendFCM.sendMessage(
                payload: SendFCM.getPayload(
                    to: participant.fcmToken!,
                    type: .Message,
                    callType: .MESSAGE,
                    chatId: chat!.id,
                    messageId: message.id,
                    targetOS: participant.os,
                    message: msg
                )
            )
        }
    }
    
    func addDateView(message: Message) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        var prevDate: String? = nil
        let curDate = dateFormatter.string(from: message.createdAt!)
        if messageMap[message.chatId]!.count != 0 {
            prevDate = dateFormatter.string(from: messageMap[message.chatId]![0].createdAt!)
        }
        if prevDate == nil || prevDate != curDate {
            let dateMessage = Message(chatId: message.chatId, body: message.body)
            dateMessage.createdAt = message.createdAt
            dateMessage.isDate = true
            messageMap[message.chatId]?.insert(dateMessage, at: 0)
        }
    }
    
    func onMessageReceived(firebaseMessage fm: FirebaseMessage) {
        print("\(TAG) onMessageReceived userId \(fm.userId!), chatId \(fm.chatId != nil), message \(fm.message != nil)")
        if (fm.chatId == nil || fm.userId == nil || fm.messageId == nil || fm.message == nil) { return }
        let message = Message(id: fm.messageId!, from: fm.userId!, chatId: fm.chatId!, body: fm.message!)
        message.createdAt = Date.now
        if messageMap[fm.chatId!] == nil {
            print("\(TAG) \(#function) messageList reset \(String(describing: fm.message))")
            messageMap[fm.chatId!] = [Message]()
        }
        addDateView(message: message)
        messageMap[fm.chatId!]!.insert(message, at: 0)
        messageEvent?.onMessageReceived(message: message, fm: fm)
    }
    
    func onIncomingCall(firebaseMessage fm: FirebaseMessage) {
        print("\(TAG) onIncomingCall userId \(fm.userId!), chatId \(fm.chatId != nil), sdp \(fm.sdp != nil), fcmToken \(fm.fcmToken != nil)")
        if (fm.chatId == nil || fm.userId == nil) { return }
        if (chat == nil || chat!.id != fm.chatId) {
            getUser(id: fm.userId!) {
                SendFCM.sendMessage(
                    payload: SendFCM.getPayload(
                        to: fm.fcmToken!,
                        type: .Decline,
                        callType: .MESSAGE,
                        targetOS: self.participant.os
                    )
                )
            }
            return
        }
        
        isOffer = false
        remoteSDP = fm.sdp
        getChat(id: fm.chatId!) {
            self.answerCall()
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
                    if self.messageMap[chat.id] == nil {
                        print("\(self.TAG) \(#function) messageList reset \(chat.title)")
                        self.messageMap[chat.id] = [Message]()
                    }
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
        ChatRepository.post(chat: chat!) { err in
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
        SendFCM.sendMessage(
            payload: SendFCM.getPayload(
                to: participant.fcmToken!,
                type: fcmType,
                callType: .MESSAGE,
                chatId: chat!.id,
                targetOS: participant.os,
                sdp: sdp
            )
        )
    }
    
    func onIceCandidate(candidate: String) {
        print("\(TAG) \(#function)")
        SendFCM.sendMessage(
            payload: SendFCM.getPayload(
                to: participant.fcmToken!,
                type: .Ice,
                callType: .MESSAGE,
                chatId: chat!.id,
                targetOS: participant.os,
                sdp: candidate
            )
        )
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
    
    func onMessage(msg: String) {
        print("\(TAG) \(#function)")
        let message = Message(from: participant.id, chatId: chat!.id, body: msg)
        message.createdAt = Date.now
        print("\(TAG) chatId \(chat!.id)")
        if messageMap[chat!.id] == nil {
            print("\(TAG) \(#function) messageList reset \(chat!.title)")
            messageMap[chat!.id] = [Message]()
        }
        addDateView(message: message)
        messageMap[chat!.id]?.insert(message, at: 0)
        messageEvent?.onMessageReceived(message: message, fm: nil)
    }
    
    func onLocalVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) \(#function)")
    }
    
    func onRemoteVideoTrack(track: RTCVideoTrack) {
        print("\(TAG) onRemoteVideoTrack")
    }
}

protocol MessageEvent {
    func onMessageReceived(message: Message, fm: FirebaseMessage?)
}
