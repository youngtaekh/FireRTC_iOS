//
//  Relation.swift
//  FireRTC
//
//  Created by young on 2023/07/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

let FROM = "from"
let TO = "to"
let TYPE = "type"

class Relation: Decodable {
    let id: String
    let from: String
    let to: String
    var type: RelationType
    let createdAt: Date?
    
    init(from: String, to: String, createdAt: Date? = nil) {
        self.id = "\(from)\(to)".sha256()
        self.from = from
        self.to = to
        self.type = .Friend
        self.createdAt = createdAt
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = id
        map[FROM] = from
        map[TO] = to
        map[TYPE] = type.rawValue
        if (createdAt != nil) {
            map[CREATED_AT] = createdAt!
        } else {
            map[CREATED_AT] = FieldValue.serverTimestamp()
        }
        return map
    }
    
    func toString() {
        var str = "User(from \(from), to \(to), type \(type)"
        if (createdAt != nil) {
            str += ", createAt \(createdAt!)"
        }
        str += ", id \(id)"
        str += ")"
        print(str)
    }
}

enum RelationType: String, Decodable {
    case Friend = "Friend"
    case Hide = "Hide"
    case Block = "Block"
}
