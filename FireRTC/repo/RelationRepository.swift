//
//  RelationRepository.swift
//  FireRTC
//
//  Created by young on 2023/07/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class RelationRepository {
    private static let TAG = "RelationRepository"
    private static let COLLECTION = "relations"
    
    private static var reload: (() -> Void)?
    
    private static let postResult: ((Error?) -> Void) = { err in
        if let err = err {
            print("\(TAG) Error writing document: \(err)")
        } else {
            print("\(TAG) Document successfully written!")
        }
    }
    
    private static let getAllResult: (QuerySnapshot?, Error?) -> Void = { query, err in
        if let err = err {
            print("\(TAG) Error get queryDocuments: \(err)")
        } else {
            var list: [String] = []
            for document in query!.documents {
                list.append(document.data()[TO] as! String)
                print("\(document.documentID) => \(document.data())")
            }
            if (list.isEmpty) {
                print("relation list is empty")
            } else {
                UserRepository.getUsers(source: .server, list: list, reload: reload!)
            }
        }
    }
    
    private static let removeResult: ((Error?) -> Void) = { err in
        if let err = err {
            print("\(TAG) Error delete document: \(err)")
        } else {
            print("\(TAG) Document successfully delete!")
        }
    }
    
    static func post(
        relation: Relation,
        completion: @escaping (Error?) -> Void = postResult
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(relation.id)
            .setData(relation.toMap(), completion: completion)
    }
    
    static func getAll(
        source: FirestoreSource,
        reload: @escaping () -> Void,
        completion: @escaping (QuerySnapshot?, Error?) -> Void = getAllResult
    ) {
        print("\(TAG) getAll")
        RelationRepository.reload = reload
        Firestore.firestore().collection(COLLECTION)
            .whereField(FROM, isEqualTo: SharedPreference.instance.getID())
            .order(by: TO)
            .getDocuments(source: source, completion: completion)
    }
    
    static func remove(
        id: String,
        completion: @escaping (Error?) -> Void = removeResult
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document("\(SharedPreference.instance.getID())\(id)")
            .delete(completion: completion)
    }
}
