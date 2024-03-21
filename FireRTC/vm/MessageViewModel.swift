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
    var message: Message? = nil
    var messageMap = [String: [Message]]()
    var participant: User!
    var messageList: [Message] {
        get {
            return (chat == nil || messageMap[chat!.id] == nil) ? [Message]() : messageMap[chat!.id]!
        }
    }
    
    var getMessageTime: Double? = nil
    
    var rtpManager = RTPManager()
    var isOffer = true
    var isConnected = false
    var isTerminated = false
    var remoteSDP: String? = nil
    
    var controllerEvent: ControllerEvent?
    var messageEvent: MessageEvent?

    func release() {
        rtpManager.release()
        rtpManager = RTPManager()
        
        isConnected = false
        isTerminated = false
        remoteSDP = nil
    }
    
    func start(reload: @escaping () -> Void, completion: (() -> Void)?) {
        isOffer = true
        var ids = [String]()
        ids.append(participant.id)
        ids.append(SharedPreference.instance.getID())
        ids.sort()
        chat = Chat(title: participant.name, participants: ids)
        ChatRepository.addChatListener(id: chat!.id) { data in
            print("\(self.TAG) Current data: title \(data[TITLE] ?? "null title"), sequence \(data[LAST_SEQUENCE] ?? -1)")
            print("\(self.TAG) message == nil \(self.message == nil)")
            print("\(self.TAG) sequence \(self.message?.sequence ?? -1)")
            if (self.message?.sequence ==  -1) {
                self.message!.sequence = data[LAST_SEQUENCE] as! Int64
                MessageRepository.post(message: self.message!) { err in
                    if let err = err {
                        print("\(self.TAG) \(err.localizedDescription)")
                    }
                }
                if self.isConnected {
                    self.rtpManager.sendData(msg: self.message!.toJson())
                } else {
                    SendFCM.sendMessage(
                        payload: SendFCM.getPayload(
                            to: self.participant.fcmToken!,
                            type: .Message,
                            callType: .MESSAGE,
                            chatId: self.chat!.id,
                            messageId: self.message!.id,
                            targetOS: self.participant.os,
                            sequence: self.message!.sequence,
                            message: self.message!.body
                        )
                    )
                }
            }
        }
        getChat(id: chat!.id, reload: reload) {
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
        message = Message(chatId: chat!.id, body: msg)
        message!.createdAt = Date.now
        print("\(TAG) chatId \(chat!.id)")
        if messageMap[chat!.id] == nil {
            print("\(TAG) \(#function) messageList reset \(chat!.title)")
            messageMap[chat!.id] = [Message]()
        }
        addDateView(message: message!)
        
        messageMap[chat!.id]?.insert(message!, at: 0)
        chat!.lastMessage = msg
        updateLastMessage()
    }
    
    func addDateView(message: Message, at: Int = 0) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        var prevDate: String? = nil
        let curDate = dateFormatter.string(from: message.createdAt!)
        if messageMap[message.chatId]!.count != at {
            prevDate = dateFormatter.string(from: messageMap[message.chatId]![at].createdAt!)
        }
        if prevDate == nil || prevDate != curDate {
            let dateMessage = Message(chatId: message.chatId, body: message.body)
            dateMessage.sequence = message.sequence
            dateMessage.createdAt = message.createdAt
            dateMessage.isDate = true
            messageMap[message.chatId]?.insert(dateMessage, at: at)
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
        answerCall()
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
    private func getChat(id: String, reload: @escaping () -> Void, handler: (() -> Void)? = nil) {
        ChatRepository.getChat(id: id) { result in
            switch result {
                case .success(let chat):
                    print("\(self.TAG) getChat success")
                    chat.toString()
                    self.chat = chat
//                    self.getLastMessage()
                    self.messageMap[chat.id] = [Message]()
                    self.getMessages(chatId: chat.id, reload: reload)
                    if handler != nil {
                        handler!()
                    }
                case.failure(let err):
                    print("\(self.TAG) getChat failure \(err)")
                    self.postChat()
                    
            }
        }
    }
    
    private func postChat() {
        ChatRepository.post(chat: chat!) { err in
            if let err = err {
                print("\(self.TAG) chat post error \(err)")
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
    
    private func updateLastMessage(handler: (() -> Void)? = nil) {
        ChatRepository.updateLastMessage(chat: chat!) { err in
            if let error = err {
                print("\(self.TAG) update last message \(error)")
            } else {
                handler?()
            }
        }
    }
    
    private func getLastMessage() {
        MessageRepository.getLastMessage(chatId: chat!.id) { query, err in
            if let err = err {
                print("\(self.TAG) \(err.localizedDescription)")
            } else {
                for document in query!.documents {
                    let message = Message.fromMap(map: document.data())
                    message.toString()
                }
            }
        }
    }
    
    func getMessages(
        chatId: String,
        aboveOf: Int64 = -1,
        underOf: Int64 = MAX_SEQUENCE,
        isAdditional: Bool = false,
        reload: @escaping () -> Void,
        setEndReload: (() -> Void)? = nil
    ) {
        getMessageTime = Date().timeIntervalSince1970
        MessageRepository.getMessages(
            chatId: chatId,
            max: underOf,
            min: aboveOf
        ) { query, err in
            print("\(self.TAG) getMessages Time : \(Date().timeIntervalSince1970 - self.getMessageTime!)ms")
            var index = 0
            if isAdditional {
                print("\(self.TAG) getMessage \(aboveOf) - \(underOf)")
                index = self.messageMap[chatId]!.count
            }
            for document in query!.documents.reversed() {
                let message = Message.fromMap(map: document.data())
                self.addDateView(message: message, at: index)
                self.messageMap[chatId]!.insert(message, at: index)
            }
            reload()
            if query!.documents.isEmpty {
                setEndReload?()
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
        var dic: [String: Any] = [String: Any]()
        do {
            dic = try JSONSerialization.jsonObject(with: Data(msg.utf8), options: []) as! [String : Any]
            let message = Message(id: dic[ID] as! String, from: dic[FROM] as! String, chatId: dic[CHAT_ID] as! String, body: dic[BODY] as! String, sequence: dic[SEQUENCE] as! Int64, createdAt: Date(timeIntervalSince1970: dic[CREATED_AT] as! Double / 1_000))
            print("\(TAG) chatId \(chat!.id)")
            if messageMap[chat!.id] == nil {
                print("\(TAG) \(#function) messageList reset \(chat!.title)")
                messageMap[chat!.id] = [Message]()
            }
            addDateView(message: message)
            messageMap[chat!.id]?.insert(message, at: 0)
            messageEvent?.onMessageReceived(message: message, fm: nil)
        } catch {
            print("\(self.TAG) \(error.localizedDescription)")
        }
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
