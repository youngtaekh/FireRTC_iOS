//
//  SpaceRepository.swift
//  FireRTC
//
//  Created by young on 2023/08/01.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class SpaceRepository {
    private static let TAG = "SpaceRepository"
    private static let COLLECTION = "spaces"
    
    static func post(
        space: Space,
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(space.id)
            .setData(space.toMap(), completion: completion)
    }
    
    static func getSpace(
        id: String,
        completion: @escaping (Result<Space, Error>) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(id).getDocument(as: Space.self, completion: completion)
    }
    
    static func getActiveSpace(
        name: String,
        completion: @escaping (QuerySnapshot?, Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .whereField(NAME, isEqualTo: name)
            .whereField(SPACE_STATUS, in: Space.notTerminated())
            .limit(to: 1)
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
    
    static func updateStatus(
        space: Space,
        reason: String = "Bye",
        completion: @escaping (Error?) -> Void
    ) {
        if space.terminated {
            let map: [String: Any] = [
                TERMINATED: true,
                TERMINATED_BY: SharedPreference.instance.getID(),
                TERMINATED_REASON: reason,
                TERMINATED_AT: FieldValue.serverTimestamp()
            ]
            Firestore.firestore().collection(COLLECTION)
                .document(space.id)
                .updateData(map, completion: completion)
        } else {
            Firestore.firestore().collection(COLLECTION)
                .document(space.id)
                .updateData([CONNECTED: space.connected], completion: completion)
        }
    }
    
    static func addCallList(
        spaceId: String,
        callId: String,
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(spaceId)
            .updateData(
                [CALLS: FieldValue.arrayUnion([callId])],
                completion: completion
            )
    }
    
    static func addParticipantList(
        spaceId: String,
        participantId: String,
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(spaceId)
            .updateData(
                [PARTICIPANTS: FieldValue.arrayUnion([participantId])],
                completion: completion
            )
    }
    
    static func addLeaveList(
        spaceId: String,
        participantId: String,
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(spaceId)
            .updateData(
                [LEAVES: FieldValue.arrayUnion([participantId])],
                completion: completion
            )
    }
    
    static func removeCallList(
        spaceId: String,
        callId: String,
        completion: @escaping (Error?) -> Void
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(spaceId)
            .updateData(
                [CALLS: FieldValue.arrayRemove([callId])],
                completion: completion
            )
    }
}
