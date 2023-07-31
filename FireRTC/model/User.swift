//
//  User.swift
//  FireRTC
//
//  Created by young on 2023/07/19.
//

import Foundation
import FirebaseFirestore

let ID = "id"
let PASSWORD = "password"
let NAME = "name"
let FCM_TOKEN = "fcmToken"
let CREATED_AT = "createdAt"

class User: Decodable {
    var id: String
    var password: String
    var name: String
    var fcmToken: String?
    let createdAt: Date?
    
    init(id: String, password: String, fcmToken: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.password = password
        self.name = id
        self.fcmToken = fcmToken
        self.createdAt = createdAt
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = id
        map[PASSWORD] = password
        map[NAME] = name
        if (fcmToken != nil) {
            map[FCM_TOKEN] = fcmToken!
        }
        if (createdAt != nil) {
            map[CREATED_AT] = createdAt!
        } else {
            map[CREATED_AT] = FieldValue.serverTimestamp()
        }
        return map
    }
    
    func toString() -> String {
        var str = "User(id \(id), name \(name)"
        if (createdAt != nil) {
            str += ", createAt \(createdAt!)"
        }
        if fcmToken != nil {
            str += ", fcmToken \(fcmToken!)"
        }
        str += ")"
        return str
    }
}
