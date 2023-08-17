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
let CALL_ID = "callId"
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
    let type: Category
    let direction: Direction
    var connected: Bool
    var terminated: Bool
    
    var sdp: String?
    var candidates: [String]?
    var isHeader: Bool?
    
    static func fromMap(map: [String: Any]) -> Call {
        return Call(
            id: (map[ID] as! String),
            userId: map[USER_ID] as! String,
            spaceId: map[SPACE_ID] as! String,
            fcmToken: map[FCM_TOKEN] as! String,
            createdAt: (map[CREATED_AT] as! Timestamp).dateValue(),
            terminatedAt: (map[TERMINATED_AT] as? Timestamp)?.dateValue(),
            counterpartName: map[COUNTERPART_NAME] as! String,
            type: Category(rawValue: map[CATEGORY] as? String ?? Category.AUDIO.rawValue) ?? .AUDIO,
            direction: Direction(rawValue: map[DIRECTION] as! String)!,
            connected: map[CONNECTED] as! Bool,
            terminated: map[TERMINATED] as! Bool,
            sdp: map[SDP] as? String,
            candidates: map[CANDIDATES] as? [String] ?? [String](),
            isHeader: false
        )
    }
    
    init(
        id: String? = nil,
        userId: String = SharedPreference.instance.getID(),
        spaceId: String,
        fcmToken: String = SharedPreference.instance.getFcmToken(),
        createdAt: Date? = nil,
        terminatedAt: Date? = nil,
        counterpartName: String,
        type: Category = .AUDIO,
        direction: Direction = .Offer,
        connected: Bool = false,
        terminated: Bool = false,
        sdp: String? = nil,
        candidates: [String] = [String](),
        isHeader: Bool = false
    ) {
        self.userId = userId
        self.spaceId = spaceId
        self.id = id ?? "\(userId)\(spaceId)\(Date().timeIntervalSince1970)".sha256()
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.terminatedAt = terminatedAt
        
        self.type = type
        self.direction = direction
        self.counterpartName = counterpartName
        self.connected = connected
        self.terminated = terminated
        
        self.sdp = sdp
        self.candidates = candidates
        self.isHeader = isHeader
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = self.id
        map[USER_ID] = self.userId
        map[SPACE_ID] = self.spaceId
        map[FCM_TOKEN] = self.fcmToken
        
        map[COUNTERPART_NAME] = self.counterpartName
        map[CATEGORY] = self.type.rawValue
        map[DIRECTION] = self.direction.rawValue
        map[CONNECTED] = self.connected
        map[TERMINATED] = self.terminated
        
        if self.candidates != nil { map[CANDIDATES] = self.candidates }
        map[CREATED_AT] = self.createdAt ?? FieldValue.serverTimestamp()
        if self.sdp != nil { map[SDP] = self.sdp! }
        return map
    }
    
    func toString() -> String {
        var str = "Call(userId \(userId), counterpartName \(counterpartName), type \(type), direction \(direction), connected \(connected), terminated \(terminated), candidates \(candidates?.count ?? 0)"
        if (createdAt != nil) {
            str += ", createAt \(createdAt!)"
        }
//        str += ", id \(id)"
        str += ")"
        return str
    }
    
    enum Category: String, Decodable {
        case AUDIO, VIDEO, SCREEN, MESSAGE, CONFERENCE
    }
    
    enum Direction: String, Decodable {
        case Offer, Answer
    }
}
