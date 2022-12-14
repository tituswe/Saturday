//
//  UserService.swift
//  Saturday
//
//  Created by Titus Lowe on 6/7/22.
//

import Firebase
import FirebaseFirestoreSwift

struct UserService {
    
    //MARK: Original methods
    func fetchUser(withUid uid: String, completion: @escaping(User) -> Void) {
        Firestore.firestore().collection("users")
            .document(uid)
            .getDocument { snapshot, _ in
                guard let snapshot = snapshot else { return }

                guard let user = try? snapshot.data(as: User.self) else { return }
                completion(user)
            }
    }
    
    func fetchTracker(withUid uid: String, completion: @escaping(Tracker) -> Void) {
        Firestore.firestore().collection("trackers")
            .document(uid)
            .getDocument { snapshot, _ in
                guard let snapshot = snapshot else { return }

                guard let tracker = try? snapshot.data(as: Tracker.self) else { return }
                completion(tracker)
            }
    }
    
    func fetchUsers(completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("users")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let users = documents.compactMap({ try? $0.data(as: User.self) })
                completion(users)
            }
    }
    
    func fetchFriendRequests(withUid uid: String, completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("friendRequests")
            .document(uid)
            .collection("senders")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let users = documents.compactMap({ try? $0.data(as: User.self) })
                completion(users)
            }
    }
    
    func fetchSentFriendRequests(withUid uid: String, completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("friendRequests")
            .document(uid)
            .collection("receivers")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let users = documents.compactMap({ try? $0.data(as: User.self) })
                completion(users)
            }
    }
    
    func fetchFriends(withUid uid: String, completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("friends")
            .document(uid)
            .collection("list")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let users = documents.compactMap({ try? $0.data(as: User.self) })
                completion(users)
            }
    }
    
    func fetchBlockedUsers(withUid uid: String, completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("blocks")
            .document(uid)
            .collection("blocked")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let blockedUsers = documents.compactMap({ try? $0.data(as: User.self) })
                completion(blockedUsers)
            }
    }
    
    func fetchBlockedByUsers(withUid uid: String, completion: @escaping([User]) -> Void) {
        Firestore.firestore().collection("blocks")
            .document(uid)
            .collection("blockedby")
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let blockedByUsers = documents.compactMap({ try? $0.data(as: User.self) })
                completion(blockedByUsers)
            }
    }
}
