//
//  AuthenticationViewModel.swift
//  Saturday
//
//  Created by Titus Lowe on 5/7/22.
//

import SwiftUI
import Firebase
import Kingfisher

class UserViewModel: ObservableObject {
    
    @Published var userSession: FirebaseAuth.User?
    @Published var didAuthenticateUser: Bool = false
    private var tempUserSession: FirebaseAuth.User?
    
    @Published var currentUser: User?
    @Published var friends = [User]()
    @Published var friendRequests = [User]()
    @Published var sentFriendRequests = [User]()
    
    @Published var users = [User]()
    
    @Published var debts = [Debt]()
    @Published var debtItems = [String : [Item]]() // [transactionId : items]
    @Published var totalPayable = 0.0
    
    @Published var credits = [Credit]()
    @Published var creditItems = [String : [Item]]() // [transactionId : items]
    @Published var totalReceivable = 0.0
    
    @Published var archives = [Archive]()
    
    init() {
        print("DEBUG: Initializing new UserViewModel...")
        self.userSession = Auth.auth().currentUser
        self.fetchUser()
        self.fetchUsers()
        self.fetchFriends()
        self.fetchFriendRequests()
        self.fetchSentFriendRequests()
        
        self.fetchDebts()
        self.fetchDebtItems()
        self.updateTotalPayable()

        self.fetchCredits()
        self.fetchCreditItems()
        self.updateTotalReceivable()
        
        self.fetchArchives()
    }
    
    func refresh() {
        print("DEBUG: Refreshing...")
        self.searchText = ""
        self.fetchUser()
        self.fetchUsers()
        self.fetchFriends()
        self.fetchFriendRequests()
        self.fetchSentFriendRequests()
        
        self.fetchDebts()
        self.fetchDebtItems()
        self.updateTotalPayable()
        
        self.fetchCredits()
        self.fetchCreditItems()
        self.updateTotalReceivable()
        
        self.fetchArchives()
    }
    
    func reset() {
        self.searchText = ""
        self.friendRequests = [User]()
        self.users = [User]()
        self.debts = [Debt]()
        self.totalPayable = 0.0
        self.credits = [Credit]()
        self.totalReceivable = 0.0
    }
    
    func login(withEmail email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("DEBUG: Failed to sign in with error \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else { return }
            self.userSession = user
            self.refresh()
            print("DEBUG: Did log user in... \(user.displayName ?? "")")
        }
    }
    
    func register(withEmail email: String, password: String, name: String, username: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("DEBUG: Failed to register with error \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else { return }
            self.tempUserSession = user
            
            let data = ["email": email,
                        "username": username.lowercased(),
                        "name": name,
                        "uid": user.uid]
            
            Firestore.firestore().collection("users")
                .document(user.uid)
                .setData(data) { _ in
                    self.didAuthenticateUser = true
                }
            
        }
    }
    
    func logout() {
        self.reset()
        userSession = nil
        try? Auth.auth().signOut()
    }
    
    func uploadProfileImage(_ image: UIImage) {
        guard let uid = tempUserSession?.uid else { return }
        
        ImageUploader.uploadImage(image: image) { profileImageUrl in
            Firestore.firestore().collection("users")
                .document(uid)
                .updateData(["profileImageUrl": profileImageUrl]) { _ in
                    self.userSession = self.tempUserSession
                    self.fetchUser()
                }
        }
    }
    
    
    // MARK: User Services
    private let userService = UserService()
    
    func fetchUser() {
        guard let uid = self.userSession?.uid else { return }
        
        userService.fetchUser(withUid: uid) { user in
            self.currentUser = user
            print("DEBUG: Fetching data from \(user.name)")
        }
    }

    func queryUser(withUid uid: String) -> User {
        guard let query = (self.users.first { $0.id == uid }) else {
            return User(id: "",
                        name: "",
                        username: "",
                        profileImageUrl: "",
                        email: "")
        }
        return query
    }
    
    func fetchUsers() {
        userService.fetchUsers { users in
            self.users = users
        }
        self.users.sort { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    @Published var searchText = ""
    
    var searchableUsers: [User] {
        let lowercasedQuery = searchText.lowercased()
        
        if let currentUser = currentUser {
            return users.filter({
                ($0.username.contains(lowercasedQuery) ||
                 $0.name.lowercased().contains(lowercasedQuery)) &&
                $0.id! != currentUser.id
            })
        } else {
            return users.filter({
                $0.username.contains(lowercasedQuery) ||
                $0.name.lowercased().contains(lowercasedQuery)
            })
        }
    }
    
    var searchableRequests: [User] {
        let lowercasedQuery = searchText.lowercased()
        
        return friendRequests.filter({
            $0.username.contains(lowercasedQuery) ||
            $0.name.lowercased().contains(lowercasedQuery)
        })
    }
    
    func sendFriendRequest(user: User) {
        guard let currentUser = currentUser else { return }
        guard let receiverUid = user.id else { return }
        
        let data = ["email": currentUser.email,
                    "username": currentUser.username.lowercased(),
                    "name": currentUser.name,
                    "profileImageUrl": currentUser.profileImageUrl,
                    "uid": currentUser.id]
        
        Firestore.firestore().collection("friendRequests")
            .document(receiverUid)
            .collection("senders")
            .document(currentUser.id!)
            .setData(data as [String : Any])
        
        let data2 = ["email": user.email,
                    "username": user.username.lowercased(),
                    "name": user.name,
                    "profileImageUrl": user.profileImageUrl,
                    "uid": receiverUid]
        
        Firestore.firestore().collection("friendRequests")
            .document(currentUser.id!)
            .collection("receivers")
            .document(receiverUid)
            .setData(data2 as [String : Any])
        
        print("DEBUG: Friend request sent!")
    }
    
    func retractFriendRequest(user: User) {
        guard let currentUser = currentUser else { return }
        guard let receiverUid = user.id else { return }
        
        Firestore.firestore().collection("friendRequests")
            .document(receiverUid)
            .collection("senders")
            .document(currentUser.id!)
            .delete { error in
                if let error = error {
                    print("DEBUG: Could not remove document: \(error.localizedDescription)")
                    return
                }
            }
        
        Firestore.firestore().collection("friendRequests")
            .document(currentUser.id!)
            .collection("receivers")
            .document(receiverUid)
            .delete { error in
                if let error = error {
                    print("DEBUG: Could not remove document: \(error.localizedDescription)")
                    return
                }
            }
        
        print("DEBUG: Friend request retracted!")
    }
    
    func fetchFriendRequests() {
        guard let uid = self.userSession?.uid else { return }
        
        userService.fetchFriendRequests(withUid: uid) { friendRequests in
            self.friendRequests = friendRequests
            print("DEBUG: Fetching friend requests...")
        }
    }
    
    func fetchSentFriendRequests() {
        guard let uid = self.userSession?.uid else { return }
        
        userService.fetchSentFriendRequests(withUid: uid) { requests in
            self.sentFriendRequests = requests
            print("DEBUG: Fetching sent friend requests...")
        }
    }
    
    func hasFriendRequest(user: User) -> Bool {
        for request in friendRequests {
            if user.id == request.id {
                return true
            }
        }
        return false
    }
    
    func hasSentFriendRequest(user: User) -> Bool {
        for request in sentFriendRequests {
            if user.id == request.id {
                return true
            }
        }
        return false
    }
    
    func acceptFriendRequest(user: User) {
        guard let currentUser = currentUser else { return }
        guard let senderUid = user.id else { return }
        
        // Add me to friend
        let data = ["email": currentUser.email,
                    "username": currentUser.username.lowercased(),
                    "name": currentUser.name,
                    "profileImageUrl": currentUser.profileImageUrl,
                    "uid": currentUser.id]
        
        Firestore.firestore().collection("friends")
            .document(senderUid)
            .collection("list")
            .document(currentUser.id!)
            .setData(data as [String : Any])
        
        // Add friend to me
        let data2 = ["email": user.email,
                    "username": user.username.lowercased(),
                    "name": user.name,
                    "profileImageUrl": user.profileImageUrl,
                    "uid": user.id]
        
        Firestore.firestore().collection("friends")
            .document(currentUser.id!)
            .collection("list")
            .document(user.id!)
            .setData(data2 as [String : Any])
        
        // Remove from requests
        Firestore.firestore().collection("friendRequests")
            .document(currentUser.id!)
            .collection("senders")
            .document(senderUid)
            .delete { error in
                if let error = error {
                    print("DEBUG: Could not remove document: \(error.localizedDescription)")
                    return
                }
            }
        
        // Update friend request list
        self.refresh()
        
        print("DEBUG: Friend request accepted!")
    }
    
    func declineFriendRequest(user: User) {
        guard let currentUser = currentUser else { return }
        guard let senderUid = user.id else { return }
        
        // Remove from requests
        Firestore.firestore().collection("friendRequests")
            .document(currentUser.id!)
            .collection("senders")
            .document(senderUid)
            .delete { error in
                if let error = error {
                    print("DEBUG: Could not remove document: \(error.localizedDescription)")
                    return
                }
            }
        
        Firestore.firestore().collection("friendRequests")
            .document(senderUid)
            .collection("receivers")
            .document(currentUser.id!)
            .delete { error in
                if let error = error {
                    print("DEBUG: Could not remove document: \(error.localizedDescription)")
                    return
                }
            }
        
        // Update friend request list
        self.refresh()
        
        print("DEBUG: Friend request declined!")
    }
    
    func fetchFriends() {
        guard let uid = self.userSession?.uid else { return }
        
        userService.fetchFriends(withUid: uid) { friends in
            self.friends = friends
            print("DEBUG: Fetching friends...")
        }
        self.friends.sort { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    
    // MARK: Transaction Services
    let debtService = DebtService()
    
    func fetchDebts() {
        guard let uid = self.userSession?.uid else { return }
        
        debtService.fetchDebts(withUid: uid) { debts in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm E, d MMM y"
            
            let sortedDebts = debts.sorted(by: { formatter.date(from: $0.date)!.compare(formatter.date(from: $1.date)!) == .orderedAscending })
            
            self.debts = sortedDebts
            print("DEBUG: Fetching debts... \(self.debts)")
        }
    }
    
    func fetchDebtItems() {
        guard let uid = self.userSession?.uid else { return }
        
        self.debts.forEach { debt in
            debtService.fetchItems(withUid: uid, transId: debt.transactionId) { items in
                self.debtItems[debt.transactionId] = items
                print("DEBUG: Fetching debt items... \(self.debtItems)")
            }
        }
    }
    
    func updateTotalPayable() {
        var totalPayable = 0.0
        self.debts.forEach { totalPayable += $0.total }
        self.totalPayable = totalPayable
    }
    
    let creditService = CreditService()
    
    func fetchCredits() {
        guard let uid = self.userSession?.uid else { return }
        
        creditService.fetchCredits(withUid: uid) { credits in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm E, d MMM y"
            
            let sortedCredits = credits.sorted(by: { formatter.date(from: $0.date)!.compare(formatter.date(from: $1.date)!) == .orderedAscending })

            self.credits = sortedCredits
            print("DEBUG: Fetching credits... \(self.credits)")
        }
    }
    
    func fetchCreditItems() {
        guard let uid = self.userSession?.uid else { return }
        
        self.credits.forEach { credit in
            creditService.fetchItems(withUid: uid, transId: credit.transactionId) { items in
                self.creditItems[credit.transactionId] = items
                print("DEBUG: Fetching credit items... \(self.creditItems)")
            }
        }
    }
    
    func updateTotalReceivable() {
        var totalReceivable = 0.0
        self.credits.forEach { totalReceivable += $0.total }
        self.totalReceivable = totalReceivable
    }
    
    // For settling payment
    func cacheTransaction(debt: Debt) {
        let transactionId = debt.transactionId
        guard let uid = self.userSession?.uid else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm E, d MMM y"

        let currDate = formatter.string(from: Date.now)
     
        let data = ["transactionId": transactionId,
                    "creditorId": debt.creditorId,
                    "dateIssued": debt.date,
                    "dateSettled": currDate,
                    "total": debt.total,
                    "status": "paid",
                    "type": "debt"] as [String : Any]
        
        Firestore.firestore().collection("history").document(uid).collection("archives").document(transactionId)
            .setData(data)
        
        self.debtItems[transactionId]?.forEach({ item in
            guard let itemId = item.id else { return }
            
            Firestore.firestore().collection("debts").document(uid).collection("transactions").document(transactionId).collection("items").document(itemId)
                .delete { error in
                    if error != nil { return }
                }
        })
    
        Firestore.firestore().collection("debts").document(uid).collection("transactions").document(transactionId)
            .delete { error in
                if error != nil { return }
            }
            
        let data2 = ["transactionId": transactionId,
                     "debtorId": uid,
                     "dateIssued": debt.date,
                     "dateSettled": currDate,
                     "total": debt.total,
                     "status": "paid",
                     "type": "credit"] as [String : Any]
        
        Firestore.firestore().collection("history").document(debt.creditorId).collection("archives").document(transactionId)
            .setData(data2)
        
        self.debtItems[transactionId]?.forEach({ item in
            guard let itemId = item.id else { return }
            
            Firestore.firestore().collection("credits").document(debt.creditorId).collection("transactions").document(transactionId).collection("items").document(itemId)
                .delete { error in
                    if error != nil { return }
                }
        })
        
        Firestore.firestore().collection("credits").document(debt.creditorId).collection("transactions").document(transactionId)
            .delete { error in
                if error != nil { return }
            }
        print("DEBUG: Cached debt!")
        
        self.refresh()
    }
    
    // For cancelling debt
    func cacheTransaction(credit: Credit) {
        let transactionId = credit.transactionId
        guard let uid = self.userSession?.uid else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm E, d MMM y"

        let currDate = formatter.string(from: Date.now)
        
        let data = ["transactionId": transactionId,
                    "debtorId": credit.debtorId,
                    "dateIssued": credit.date,
                    "dateSettled": currDate,
                    "total": credit.total,
                    "status": "cancelled",
                    "type": "credit"] as [String : Any]
        
        Firestore.firestore().collection("history").document(uid).collection("archives").document(transactionId)
            .setData(data)
        
        self.creditItems[transactionId]?.forEach({ item in
            guard let itemId = item.id else { return }
            
            Firestore.firestore().collection("credits").document(uid).collection("transactions").document(transactionId).collection("items").document(itemId)
                .delete { error in
                    if error != nil { return }
                }
        })
        
        Firestore.firestore().collection("credits").document(uid).collection("transactions").document(transactionId)
            .delete { error in
                if error != nil { return }
            }
        
        let data2 = ["transactionId": transactionId,
                     "creditorId": uid,
                     "dateIssued": credit.date,
                     "dateSettled": currDate,
                     "total": credit.total,
                     "status": "cancelled",
                     "type": "debt"] as [String : Any]
        
        Firestore.firestore().collection("history").document(credit.debtorId).collection("archives").document(transactionId)
            .setData(data2)
        
        self.creditItems[transactionId]?.forEach({ item in
            guard let itemId = item.id else { return }
            
            Firestore.firestore().collection("debts").document(credit.debtorId).collection("transactions").document(transactionId).collection("items").document(itemId)
                .delete { error in
                    if error != nil { return }
                }
        })
        
        Firestore.firestore().collection("debts").document(credit.debtorId).collection("transactions").document(transactionId)
            .delete { error in
                if error != nil { return }
            }
        print("DEBUG: Cached credit!")
        
        self.refresh()
    }
    
    let archiveService = ArchiveService()
    
    func fetchArchives() {
        guard let uid = self.userSession?.uid else { return }
        
        archiveService.fetchArchives(withUid: uid) { archives in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm E, d MMM y"
            
            let sortedArchives = archives.sorted(by: { formatter.date(from: $0.dateSettled)!.compare(formatter.date(from: $1.dateSettled)!) == .orderedDescending })
            
            self.archives = sortedArchives
            print("DEBUG: Fetching archives... \(self.archives)")
        }
    }
}
