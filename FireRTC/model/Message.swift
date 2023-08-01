//
//  Message.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore

let CHAT_ID = "chatId"
let BODY = "body"

class Message: Decodable {
    let id: String
    let from: String
    let chatId: String
    let body: String
    var timeFlag = true
    var createdAt: Date? = nil
    
    init(chatId: String, body: String) {
        self.from = SharedPreference.instance.getID()
        self.chatId = chatId
        self.id = "\(from)\(chatId)\(Date().timeIntervalSince1970)"
        self.body = body
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = self.id
        map[FROM] = self.from
        map[CHAT_ID] = self.chatId
        map[BODY] = self.body
        if createdAt == nil {
            map[CREATED_AT] = FieldValue.serverTimestamp()
        } else {
            map[CREATED_AT] = self.createdAt!
        }
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