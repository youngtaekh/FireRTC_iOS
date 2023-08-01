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
let MODIFIED_AT = "modifiedAt"

class Chat: Decodable {
    let id: String
    let title: String
    let participants: [String]
    var lastMessage = ""
    let isGroup: Bool
    var createdAt: Date? = nil
    var modifiedAt: Date? = nil
    
    init(title: String, participants: [String]) {
        if (participants.count > 1) {
            self.id = "\(participants[0])\(participants[1])"
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
        map[IS_GROUP] = self.isGroup
        if self.createdAt == nil {
            map[CREATED_AT] = FieldValue.serverTimestamp()
        } else {
            map[CREATED_AT] = self.createdAt
        }
        if self.modifiedAt == nil {
            map[MODIFIED_AT] = FieldValue.serverTimestamp()
        } else {
            map[MODIFIED_AT] = self.modifiedAt
        }
        return map
    }
    
    func toString() {
        var str = "Chat(title \(title), lastMessage \(lastMessage), participants \(participants.count)"
        if (createdAt != nil) {
            str += ", createAt \(createdAt!)"
        }
        if modifiedAt != nil {
            str += ", modifiedAt \(modifiedAt!)"
        }
        str += ")"
        print(str)
    }
}
