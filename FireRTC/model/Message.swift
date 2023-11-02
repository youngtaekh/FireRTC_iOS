//
//  Message.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore

let CHAT_ID = "chatId"
let MESSAGE_ID = "messageId"
let BODY = "body"
let MESSAGE = "message"

class Message: Decodable {
    let id: String
    let from: String
    let chatId: String
    let body: String
    var timeFlag = true
    var isDate = false
    var createdAt: Date? = nil
    
    convenience init(from: String = SharedPreference.instance.getID(), chatId: String, body: String) {
        self.init(
            id: "\(from)\(chatId)\(Date().timeIntervalSince1970)".sha256(),
            from: from,
            chatId: chatId,
            body: body
        )
    }
    
    init(id: String, from: String, chatId: String, body: String) {
        self.id = id
        self.from = from
        self.chatId = chatId
        self.body = body
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = self.id
        map[FROM] = self.from
        map[CHAT_ID] = self.chatId
        map[BODY] = self.body
        map[CREATED_AT] = self.createdAt ?? FieldValue.serverTimestamp()
        return map
    }
    
    func toString() {
        var str = "Message(from \(from), body \(body)"
        if (createdAt != nil) {
            str += ", createAt \(createdAt!)"
        }
        str += ")"
        print(str)
    }
}
