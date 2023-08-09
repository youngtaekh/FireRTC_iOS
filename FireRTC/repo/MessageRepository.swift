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
    
    static func getMessages(chatId: String, completion: @escaping (QuerySnapshot?, Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(CHAT_ID, isEqualTo: chatId)
            .order(by: CREATED_AT, descending: true)
            .limit(to: 100)
            .getDocuments(completion: completion)
    }
}
