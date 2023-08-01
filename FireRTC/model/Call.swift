//
//  Call.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore

let USER_ID = "userId"
let SPACE_ID = "spaceId"
let COUNTERPART_NAME = "counterpartName"
let CATEGORY = "type"
let DIRECTION = "direction"
let SDP = "sdp"
let CANDIDATES = "candidates"

class Call: Decodable {
    let id: String
    let userId: String
    let spaceId: String
    let fcmToken: String
    var createdAt: Date? = nil
    var terminatedAt: Date? = nil
    
    let counterpartName: String
    let category: Category
    let direction: Direction
    var connected = false
    var terminated = false
    
    var sdp: String? = nil
    var candidates = [String]()
    var isHeader = false
    
    init(spaceId: String, category: Category, direction: Direction, counterpartName: String) {
        self.userId = SharedPreference.instance.getID()
        self.spaceId = spaceId
        self.id = "\(userId)\(spaceId)\(Date().timeIntervalSince1970)".sha256()
        self.fcmToken = SharedPreference.instance.getFcmToken()
        self.category = category
        self.direction = direction
        self.counterpartName = counterpartName
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = self.id
        map[USER_ID] = self.userId
        map[SPACE_ID] = self.spaceId
        map[FCM_TOKEN] = self.fcmToken
        
        map[COUNTERPART_NAME] = self.counterpartName
        map[CATEGORY] = self.category
        map[DIRECTION] = self.direction
        map[CONNECTED] = self.connected
        map[TERMINATED] = self.terminated
        
        map[CANDIDATES] = self.candidates
        if self.createdAt == nil {
            map[CREATED_AT] = FieldValue.serverTimestamp()
        } else {
            map[CREATED_AT] = self.createdAt!
        }
        if self.sdp != nil { map[SDP] = self.sdp! }
        return map
    }
    
    func toString() {
        var str = "Call(userId \(userId), counterpartName \(counterpartName), category \(category), direction \(direction), connected \(connected), terminated \(terminated), candidates \(candidates.count)"
        if (createdAt != nil) {
            str += ", createAt \(createdAt!)"
        }
//        str += ", id \(id)"
        str += ")"
        print(str)
    }
    
    enum Category: Decodable {
        case AUDIO, VIDEO, SCREEN, MESSAGE, CONFERENCE
    }
    
    enum Direction: Decodable {
        case Offer, Answer
    }
}
