//
//  AuthEnterNameViewModel.swift
//  epam_messenger
//
//  Created by Anton Pryakhin on 09.03.2020.
//

import UIKit
import Foundation
import ContactsUI
import FirebaseAuth
import PhoneNumberKit

protocol AuthEnterInitialsViewModelProtocol {
    func createUser(
        userModel: UserModel,
        avatar: UIImage?,
        progressAddiction: @escaping (Float) -> Void,
        completion: @escaping (Error?) -> Void
    )
}

class AuthEnterInitialsViewModel: AuthEnterInitialsViewModelProtocol {
    
    // MARK: - Vars
    
    let router: RouterProtocol
    let viewController: AuthEnterInitialsViewControllerProtocol
    
    let firestoreService: FirestoreServiceProtocol
    let storageService: StorageServiceProtocol
    
    // MARK: - Init
    
    init(
        router: RouterProtocol,
        viewController: AuthEnterInitialsViewControllerProtocol,
        firestoreService: FirestoreServiceProtocol = FirestoreService(),
        storageService: StorageServiceProtocol = StorageService()
    ) {
        self.router = router
        self.viewController = viewController
        self.firestoreService = firestoreService
        self.storageService = storageService
    }
    
    // MARK: - Methods
    
    func createUser(
        userModel: UserModel,
        avatar: UIImage?,
        progressAddiction: @escaping (Float) -> Void,
        completion: @escaping (Error?) -> Void
    ) {
        let createGroup = DispatchGroup()
        
        var err: Error?
        var totalSteps: Float = 0
        let timestamp = Date()
        
        totalSteps += 1
        createGroup.enter()
        let userId = firestoreService.createUser(userModel) { error in
            if error != nil {
                err = error
            }
            progressAddiction(1 / totalSteps)
            createGroup.leave()
        }
        
        if let avatar = avatar {
            totalSteps += 1
            createGroup.enter()
            storageService.uploadUserAvatar(
                userId: userId,
                avatar: avatar,
                timestamp: timestamp
            ) { _, error in
                if error != nil {
                    err = error
                }
                progressAddiction(1 / totalSteps)
                createGroup.leave()
            }
        }
        
        totalSteps += 1
        createGroup.enter()
        let allContacts = getContacts()
        firestoreService.searchUsers(
            by: allContacts.map { $0.number }
        ) { [weak self] contactList, last in
            guard let self = self else { return }
            
            if let contactList = contactList {
                
                let chatsGroup = DispatchGroup()
                
                for contact in contactList {
                    chatsGroup.enter()
                    self.firestoreService.createContact(
                        .fromUser(
                            contact,
                            localName: allContacts.first { $0.number == contact.phoneNumber }?.name
                                ?? contact.fullName
                        )
                    ) { error in
                        guard error == nil else {
                            err = error
                            chatsGroup.leave()
                            return
                        }
                        
                        self.firestoreService.createChat(
                            .fromUserId(
                                contact.documentId!,
                                lastMessageKind: [
                                    .text("\(userModel.name) is now in SmallTalk!")
                                ]
                            )
                        ) { error in
                            if error != nil {
                                err = error
                            }
                            chatsGroup.leave()
                        }
                    }
                }
                
                chatsGroup.notify(queue: .main) {
                    if last {
                        progressAddiction(1 / totalSteps)
                        createGroup.leave()
                    }
                }
            }
        }
        
        totalSteps += 1
        createGroup.enter()
        self.firestoreService.createChat(
            .init(
                documentId: nil,
                users: [
                    Auth.auth().currentUser!.uid
                ],
                lastMessage: .empty(),
                type: .savedMessages
        )) { chatErr in
            if chatErr != nil {
                err = chatErr
            }
            progressAddiction(1 / totalSteps)
            createGroup.leave()
        }
        
        createGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            completion(err)
            self.router.showBottomBar()
        }
    }
    
    private func getContacts() -> [(number: String, name: String?)] {
        let contactStore = CNContactStore()
        var contacts = [(number: String, name: String?)]()
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey
            ] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        do {
            try contactStore.enumerateContacts(with: request) { (contact, _) in
                let validTypes = [
                    CNLabelPhoneNumberiPhone,
                    CNLabelPhoneNumberMobile,
                    CNLabelPhoneNumberMain
                ]
                
                let numbers = contact.phoneNumbers.compactMap { phoneNumber -> String? in
                    guard let label = phoneNumber.label, validTypes.contains(label) else { return nil }
                    return phoneNumber.value.stringValue
                }.map {(
                    number: $0,
                    name: CNContactFormatter.string(from: contact, style: .fullName)
                    )}
                
                contacts.append(contentsOf: numbers)
            }
        } catch {
            print("unable to fetch contacts")
        }
        
        let phoneNumberKit = PhoneNumberKit()
        let currentPhoneNumber = Auth.auth().currentUser!.phoneNumber
        
        for (index, contact) in contacts.enumerated() {
            if let number = try? phoneNumberKit
                .parse(contact.number) {
                contacts[index].number = phoneNumberKit.format(number, toType: .e164)
            } else {
                contacts[index].number = ""
            }
        }
        let result = contacts
            .filter { $0.number != currentPhoneNumber && !$0.number.isEmpty}
            .unique { $0.number }
        
        return result
    }
}

// MARK: - Array unique by property helper

extension Array {
    func unique <T:Hashable>(by: ((Element) -> (T))) -> [Element] {
        var set = Set<T>() //the unique list kept in a Set for fast retrieval
        var arrayOrdered = [Element]() //keeping the unique list of elements but ordered
        for value in self {
            if !set.contains(by(value)) {
                set.insert(by(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}
