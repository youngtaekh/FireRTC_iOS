//
//  Chat.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore

let TITLE = "title"
let IS_GROUP = "isGroup"
let LAST_MESSAGE = "lastMessage"
let LAST_SEQUENCE = "lastSequence"
let MODIFIED_AT = "modifiedAt"

class Chat: Decodable {
    let id: String
    let title: String
    let participants: [String]
    var lastMessage = ""
    var lastSequence: Int64 = -1
    let isGroup: Bool
    var createdAt: Date? = nil
    var modifiedAt: Date? = nil
    
    init(title: String, participants: [String]) {
        if (participants.count > 1) {
            self.id = "\(participants[0])\(participants[1])".sha256()
        } else {
            self.id = ""
        }
        self.title = title
        self.participants = participants
        self.isGroup = participants.count > 2
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = self.id
        map[TITLE] = self.title
        map[PARTICIPANTS] = self.participants
        map[LAST_MESSAGE] = self.lastMessage
        map[LAST_SEQUENCE] = self.lastSequence
        map[IS_GROUP] = self.isGroup
        map[CREATED_AT] = self.createdAt ?? FieldValue.serverTimestamp()
        map[MODIFIED_AT] = self.modifiedAt ?? FieldValue.serverTimestamp()
        return map
    }
    
    func toString() {
        var str = "Chat(title \(title), lastMessage \(lastSequence) \(lastMessage), participants \(participants.count)"
        if (createdAt != nil) {
            str += ", createdAt \(createdAt!)"
        }
        if modifiedAt != nil {
            str += ", modifiedAt \(modifiedAt!)"
        }
        str += ")"
        print(str)
    }
}
