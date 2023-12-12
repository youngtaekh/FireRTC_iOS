//
//  Space.swift
//  FireRTC
//
//  Created by young on 2023/07/27.
//

import Foundation
import FirebaseFirestore

let CREATED_BY = "createdBy"
let SPACE_STATUS = "status"
let CALL_TYPE = "callType"
let TARGET_OS = "targetOS"
let CONNECTED = "connected"
let TERMINATED = "terminated"
let TERMINATED_REASON = "terminatedReason"
let TERMINATED_BY = "terminatedBy"
let TERMINATED_AT = "terminatedAt"
let MAXIMUM = "maximum"
let CALLS = "calls"
let PARTICIPANTS = "participants"
let LEAVES = "leaves"

class Space: Decodable {
    let name: String
    let id: String
    let createdBy: String
    var createdAt: Date? = nil
    
    var status: SpaceStatus? = .INACTIVE
    let callType: Call.Category
    var connected = false
    var terminated = false
    var terminatedReason: String? = nil
    var terminatedBy: String? = nil
    var terminatedAt: Date? = nil
    
    var maximum: Int
    var calls: [String]
    var participants: [String]
    var leaves: [String]
    
    init(callType: Call.Category) {
        self.name = SharedPreference.instance.getID()
        self.id = "\(self.name)\(Date().timeIntervalSince1970))".sha256()
        self.createdBy = SharedPreference.instance.getID()
        self.callType = callType
        self.maximum = 2
        self.calls = []
        self.participants = [SharedPreference.instance.getID()]
        self.leaves = []
    }
    
    init(id: String, name: String, createdBy: String, callType: Call.Category, maximum: Int) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.callType = callType
        self.maximum = maximum
        self.calls = []
        self.participants = []
        self.leaves = []
    }
    
    static func fromMap(map: [String: Any]) -> Space {
        let space = Space(
            id: map[ID] as! String,
            name: map[NAME] as! String,
            createdBy: map[CREATED_BY] as! String,
            callType: Call.Category(rawValue: map[CATEGORY] as! String)!,
            maximum: map[MAXIMUM] as! Int
        )
        space.createdAt = (map[CREATED_AT] as! Timestamp).dateValue()
        space.status = SpaceStatus(rawValue: map[SPACE_STATUS] as! String) ?? .INACTIVE
        space.connected = map[CONNECTED] as? Bool ?? false
        space.terminated = map[TERMINATED] as? Bool ?? false
        space.terminatedReason = map[TERMINATED_REASON] as? String
        space.terminatedBy = map[TERMINATED_BY] as? String
        space.terminatedAt = (map[TERMINATED_AT] as? Timestamp)?.dateValue()
        space.calls = map[CALLS] as! [String]
        space.participants = map[PARTICIPANTS] as! [String]
        space.leaves = map[LEAVES] as! [String]
        return space
    }
    
    func toMap() -> [String : Any] {
        var map = [String : Any]()
        map[ID] = self.id
        map[NAME] = self.name
        map[CREATED_BY] = self.createdBy
        
        map[SPACE_STATUS] = self.status?.rawValue
        map[CALL_TYPE] = self.callType.rawValue
        map[CONNECTED] = self.connected
        map[TERMINATED] = self.terminated
        
        map[MAXIMUM] = self.maximum
        map[CALLS] = self.calls
        map[PARTICIPANTS] = self.participants
        map[LEAVES] = self.leaves
        
        map[CREATED_AT] = self.createdAt ?? FieldValue.serverTimestamp()
        return map
    }
    
    func toString() -> String {
        var str = "Space(name \(name), createdBy \(createdBy), callType \(callType), connected \(connected), terminated \(terminated)"
        if (createdAt != nil) {
            str += ", createdAt \(createdAt!)"
        }
//        str += ", id \(id)"
        str += ")"
        return str
    }
    
    static func notTerminated() -> [String] {
        return [SpaceStatus.ACTIVE.rawValue, SpaceStatus.INACTIVE.rawValue]
    }
    
    enum SpaceStatus: String, Decodable {
        case INACTIVE, ACTIVE, TERMINATED
    }
}
