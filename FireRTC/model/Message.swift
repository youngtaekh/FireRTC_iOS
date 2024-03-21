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
let SEQUENCE = "sequence"
let MESSAGE = "message"
let MAX_SEQUENCE: Int64 = 9_223_372_036_854_775_807

class Message: Decodable {
    let id: String
    let from: String
    let chatId: String
    let body: String
    var sequence: Int64
    var timeFlag = true
    var isDate = false
    var createdAt: Date? = nil
    
    static func fromMap(map: [String: Any]) -> Message {
        return Message(
            id: map[ID] as! String,
            from: map[FROM] as! String,
            chatId: map[CHAT_ID] as! String,
            body: map[BODY] as! String,
            sequence: map[SEQUENCE] as! Int64,
            createdAt: (map[CREATED_AT] as! Timestamp).dateValue()
        )
    }
    
    convenience init(from: String = SharedPreference.instance.getID(), chatId: String, body: String) {
        self.init(
            id: "\(from)\(chatId)\(Date().timeIntervalSince1970)".sha256(),
            from: from,
            chatId: chatId,
            body: body
        )
    }
    
    init(id: String, from: String, chatId: String, body: String, sequence: Int64 = -1, createdAt: Date? = nil) {
        self.id = id
        self.from = from
        self.chatId = chatId
        self.body = body
        self.sequence = sequence
        self.createdAt = createdAt
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = self.id
        map[FROM] = self.from
        map[CHAT_ID] = self.chatId
        map[BODY] = self.body
        map[SEQUENCE] = self.sequence
        map[CREATED_AT] = self.createdAt ?? FieldValue.serverTimestamp()
        return map
    }
    
    func toString() {
        var str = "Message(from \(from), sequence \(sequence), body \(body)"
        if (createdAt != nil) {
            str += ", createdAt \(createdAt!)"
        }
        str += ")"
        print(str)
    }
    
    func toJson() -> String {
        let dic: [String: Any] = [
            ID: self.id,
            FROM: self.from,
            CHAT_ID: self.chatId,
            BODY: self.body,
            SEQUENCE: self.sequence,
            CREATED_AT: Int64((self.createdAt?.timeIntervalSince1970 ?? 0.0) * 1_000)
        ] as Dictionary
        
        do {
            let json = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            return String(data: json, encoding: .utf8) ?? "{}"
        } catch {
            print(error.localizedDescription)
            return "{}"
        }
    }
}
