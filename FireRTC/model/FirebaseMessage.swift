//
//  FirebaseMessage.swift
//  FireRTC
//
//  Created by young on 2023/10/30.
//

import Foundation

class FirebaseMessage {
    let userId: String?
    let spaceId: String?
    let callId: String?
    let chatId: String?
    let messageId: String?
    let type: String?
    let callType: String?
    let name: String?
    let targetOS: String?
    let sdp: String?
    let fcmToken: String?
    let message: String?
    
    init(data: [AnyHashable: Any]) {
        self.userId = data[USER_ID] as? String
        self.spaceId = data[SPACE_ID] as? String
        self.callId = data[CALL_ID] as? String
        self.chatId = data[CHAT_ID] as? String
        self.messageId = data[MESSAGE_ID] as? String
        self.type = data[TYPE] as? String
        self.callType = data[CALL_TYPE] as? String
        self.name = data[NAME] as? String
        self.targetOS = data[TARGET_OS] as? String
        self.sdp = data[SDP] as? String
        self.fcmToken = data[FCM_TOKEN] as? String
        self.message = data[MESSAGE] as? String
    }
}
