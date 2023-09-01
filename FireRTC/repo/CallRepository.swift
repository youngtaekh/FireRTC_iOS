//
//  CallRepository.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class CallRepository {
    private static let TAG = "CallRepository"
    private static let COLLECTION = "calls"
    
    static func post(
        call: Call,
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(call.id)
            .setData(call.toMap(), completion: completion)
    }
    
    static func getCall(
        id: String,
        completion: @escaping (Result<Call, Error>) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(id)
            .getDocument(as: Call.self, completion: completion)
    }
    
    static func getBySpaceId(
        spaceId: String,
        completion: @escaping (QuerySnapshot?, Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(SPACE_ID, isEqualTo: spaceId)
            .getDocuments(completion: completion)
    }
    
    static func getByUserId(
        userId: String,
        completion: @escaping (QuerySnapshot?, Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(USER_ID, isEqualTo: userId)
            .order(by: CREATED_AT, descending: true)
            .getDocuments(completion: completion)
    }
    
    static func getActiveCalls(
        spaceId: String,
        completion: @escaping (QuerySnapshot?, Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(SPACE_ID, isEqualTo: spaceId)
            .whereField(TERMINATED, isEqualTo: false)
            .limit(to: 2)
            .getDocuments(completion: completion)
    }
    
    static func update(
        id: String,
        map: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(id)
            .updateData(map, completion: completion)
    }
    
    static func updateCandidate(
        id: String,
        candidate: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(id)
            .updateData([CANDIDATES: FieldValue.arrayUnion([candidate])], completion: completion)
    }
    
    static func updateSDP(
        call: Call,
        completion: ((Error?) -> Void)? = nil
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(call.id)
            .updateData([SDP: call.sdp!], completion: completion)
    }
    
    static func updateTerminatedAt(
        id: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(id)
            .updateData(
                [
                    TERMINATED_AT: FieldValue.serverTimestamp(),
                    TERMINATED: true
                ],
                completion: completion
            )
    }
}
