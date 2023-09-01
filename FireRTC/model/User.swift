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
let OS = "os"
let FCM_TOKEN = "fcmToken"
let CREATED_AT = "createdAt"

class User: Decodable {
    var id: String
    var password: String
    var name: String
    var os: String
    var fcmToken: String?
    let createdAt: Date?
    
    init(id: String, password: String, name: String? = nil, os: String = "iOS", fcmToken: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.password = password
        self.name = (name == nil) ? id : name!
        self.os = os
        self.fcmToken = fcmToken
        self.createdAt = createdAt
    }
    
    func toMap() -> [String: Any] {
        var map = [String: Any]()
        map[ID] = id
        map[PASSWORD] = password
        map[NAME] = name
        map[OS] = os
        if (fcmToken != nil) {
            map[FCM_TOKEN] = fcmToken!
        }
        map[CREATED_AT] = self.createdAt ?? FieldValue.serverTimestamp()
        return map
    }
    
    func toString() -> String {
        var str = "User(\(ID) \(id), \(NAME) \(name), \(OS) \(os)"
        if (createdAt != nil) {
            str += ", \(CREATED_AT) \(createdAt!)"
        }
        if fcmToken != nil {
            str += ", \(FCM_TOKEN) \(fcmToken!)"
        }
        str += ")"
        return str
    }
}
