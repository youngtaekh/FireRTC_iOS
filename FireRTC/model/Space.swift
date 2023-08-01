//
//  Space.swift
//  FireRTC
//
//  Created by young on 2023/07/27.
//

import Foundation
import FirebaseFirestore

let CREATED_BY = "createdBy"
let SPACE_STATUS = "spaceStatus"
let CALL_TYPE = "callType"
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
    
    var spaceStatus = SpaceStatus.Inactive
    let callCategory: Call.Category
    var connected = false
    var terminated = false
    var terminatedReason: String? = nil
    var terminatedBy: String? = nil
    var terminatedAt: Date? = nil
    
    var maximun: Int
    var calls: [String]
    var participants: [String]
    var leaves: [String]
    
    init(name: String, callCategory: Call.Category) {
        self.name = name
        self.id = String(Date().timeIntervalSince1970).sha256()
        self.createdBy = SharedPreference.instance.getID()
        self.callCategory = callCategory
        self.maximun = 2
        self.calls = []
        self.participants = []
        self.leaves = []
    }
    
    func toMap() -> [String : Any] {
        var map = [String : Any]()
        map[ID] = self.id
        map[NAME] = self.name
        map[CREATED_BY] = self.createdBy
        
        map[SPACE_STATUS] = self.spaceStatus
        map[CALL_TYPE] = self.callCategory
        map[CONNECTED] = self.connected
        map[TERMINATED] = self.terminated
        
        map[MAXIMUM] = self.maximun
        map[CALLS] = self.calls
        map[PARTICIPANTS] = self.participants
        map[LEAVES] = self.leaves
        
        if createdAt == nil {
            map[CREATED_AT] = FieldValue.serverTimestamp()
        } else {
            map[CREATED_AT] = createdAt
        }
        return map
    }
    
    func toString() {
        var str = "Space(name \(name), createdBy \(createdBy), callCategory \(callCategory), spaceStatus \(spaceStatus)"
        if (createdAt != nil) {
            str += ", createAt \(createdAt!)"
        }
//        str += ", id \(id)"
        str += ")"
        print(str)
    }
    
    static func notTerminated() -> [String] {
        return [SpaceStatus.Active.rawValue, SpaceStatus.Inactive.rawValue]
    }
    
    enum SpaceStatus: String, Decodable {
        case Inactive = "INACTIVE"
        case Active = "ACTIVE"
        case Terminated = "TERMINATED"
    }
}
