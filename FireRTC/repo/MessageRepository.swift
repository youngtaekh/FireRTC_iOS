//
//  MessageRepository.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore

class MessageRepository {
    private static let TAG = "MessageRepository"
    private static let COLLECTION = "messages"
    
    static func post(message: Message, completion: @escaping (Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .document(message.id)
            .setData(message.toMap(), completion: completion)
    }
    
    static func getMessages(chatId: String, max: Int64, min: Int64, completion: @escaping (QuerySnapshot?, Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(CHAT_ID, isEqualTo: chatId)
            .whereField(SEQUENCE, isGreaterThan: min)
            .whereField(SEQUENCE, isLessThan: max)
            .order(by: SEQUENCE, descending: true)
            .limit(to: 100)
            .getDocuments(completion: completion)
    }

    static func getLastMessage(chatId: String, completion: @escaping (QuerySnapshot?, Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(CHAT_ID, isEqualTo: chatId)
            .order(by: SEQUENCE, descending: true)
            .limit(to: 1)
            .getDocuments(completion: completion)
    }
}
