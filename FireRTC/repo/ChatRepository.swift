//
//  ChatRepository.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore

class ChatRepository {
    private static let TAG = "ChatRepository"
    private static let COLLECTION = "chats"
    
    static func post(chat: Chat, completion: @escaping (Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .document(chat.id)
            .setData(chat.toMap(), completion: completion)
    }
    
    static func getChat(id: String, completion: @escaping (DocumentSnapshot?, Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .document(id)
            .getDocument(completion: completion)
    }
    
    static func getChats(participantId: String, completion: @escaping (QuerySnapshot?, Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(PARTICIPANTS, arrayContains: participantId)
            .order(by: MODIFIED_AT, descending: true)
            .getDocuments(completion: completion)
    }
    
    static func updateModifiedAt(id: String, completion: @escaping (Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .document(id)
            .updateData([MODIFIED_AT: FieldValue.serverTimestamp()], completion: completion)
    }
    
    static func updateLastMessage(chat: Chat, completion: @escaping (Error?) -> Void) {
        Firestore.firestore().collection(COLLECTION)
            .document(chat.id)
            .updateData([
                MODIFIED_AT: FieldValue.serverTimestamp(),
                LAST_MESSAGE: chat.lastMessage
            ], completion: completion)
    }
}
