//
//  UserRepository.swift
//  FireRTC
//
//  Created by young on 2023/07/19.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

class UserRepository {
    private static let TAG = "UserRepository"
    private static let COLLECTION = "users"
    
    private static var reload: (() -> Void)?
    
    static var contacts: [User] = [User(id: "Test01", password: "aaa"), User(id: "Test02", password: "aaa")]
    private static var totalCount = 0
    
    private static let postResult: (Error?) -> Void = { err in
        if let err = err {
            print("\(TAG) Error writing document: \(err)")
        } else {
            print("\(TAG) Document successfully written!")
        }
    }
    
    private static let getUserResult: (Result<User, Error>) -> Void = { result in
        switch result {
            case .success(let user):
                print("\(TAG) \(user.toString())")
            case .failure(let error):
                print("\(TAG) Error decoding user: \(error)")
        }
    }
    
    private static let getUsersResult: (QuerySnapshot?, Error?) -> Void = { query, err in
        if let err = err {
            print("\(TAG) Error get queryDocuments: \(err)")
        } else {
            for document in query!.documents {
                let user = User(
                    id: document.data()[ID] as! String,
                    password: document.data()[PASSWORD] as! String,
                    name: document.data()[NAME] as? String,
                    os: document.data()[OS] as! String,
                    fcmToken: document.data()[FCM_TOKEN] as? String,
                    createdAt: document.data()[CREATED_AT] as? Date)
                contacts.append(user)
            }
            if contacts.count == totalCount {
                UserRepository.reload!()
            }
        }
    }
    
    private static let updateTokenResult: (Error?) -> Void = { err in
        if let err = err {
            print("\(TAG) Error delete document: \(err)")
        } else {
            print("\(TAG) Document successfully delete!")
        }
    }
    
    private static let removeResult: (Error?) -> Void = { err in
        if let err = err {
            print("\(TAG) Error delete document: \(err)")
        } else {
            print("\(TAG) Document successfully delete!")
        }
    }
    
    static func post(user: User, completion: ((Error?) -> Void)? = postResult) {
        Firestore.firestore().collection(COLLECTION)
            .document(user.id)
            .setData(user.toMap(), completion: completion)
    }
    
    static func getUser(id: String, completion: @escaping (Result<User, Error>) -> Void = getUserResult) {
        Firestore.firestore().collection(COLLECTION)
            .document(id).getDocument(as: User.self, completion: completion)
    }
    
    static func getUsers(
        source: FirestoreSource,
        list: [String],
        reload: @escaping () -> Void,
        completion: @escaping (QuerySnapshot?, Error?) -> Void = getUsersResult
    ) {
        print("\(TAG) getUsers size \(list.count)")
        UserRepository.reload = reload
        totalCount = list.count
        contacts.removeAll()
        var start = 0
        var end = 10
        while (list.count > start) {
            end = min(end + start, list.count)
            let subList = Array(list[start ... end - 1])
            start = end
            Firestore.firestore().collection(COLLECTION)
                .whereField(ID, in: subList)
                .getDocuments(source: source, completion: completion)
        }
    }
    
    static func updateFCMToken(
        user: User,
        completion: @escaping (Error?) -> Void = updateTokenResult
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(user.id)
            .updateData([FCM_TOKEN: user.fcmToken!], completion: completion)
    }
    
    static func deleteUser(
        id: String,
        completion: @escaping (Error?) -> Void = removeResult
    ) {
        Firestore.firestore().collection(COLLECTION)
            .document(id)
            .delete(completion: completion)
    }
}
