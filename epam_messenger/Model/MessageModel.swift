//
//  MessageModel.swift
//  epam_messenger
//
//  Created by Nickolay Truhin on 08.03.2020.
//

import Foundation
import Firebase
import CodableFirebase

typealias ImageSize = CGSize

struct MessageModel: AutoCodable {
    
    var documentId: String?
    let kind: [MessageKind]
    let userId: String
    let timestamp: Timestamp
    
    enum CodingKeys: String, CodingKey {
        case documentId
        case kind
        case userId
        case timestamp
        case filename
        case enumCaseKey
    }
    
    enum MessageKind: AutoCodable {
        case text(_: String)
        case image(path: String, size: ImageSize)
        case audio(path: String)
        case forward(userId: String)
    }
    
    static let defaultDocumentId: String? = nil
    static let defaultKind: [MessageKind] = []
    
    static func empty() -> MessageModel {
        return MessageModel(kind: [], userId: Auth.auth().currentUser!.uid, timestamp: Timestamp.init())
    }
    
    static func fromSnapshot(_ snapshot: DocumentSnapshot) -> MessageModel? {
        var data = snapshot.data() ?? [:]
        data["documentId"] = snapshot.documentID
        
        do {
            return try FirestoreDecoder()
                .decode(
                    MessageModel.self,
                    from: data
            )
        } catch let err {
            debugPrint("error while parse message model: \(err)")
            return nil
        }
    }
    
    static func decodeTimestamp(from container: KeyedDecodingContainer<CodingKeys>) -> Timestamp {
        if let dict = try? container.decode([String: Int64].self, forKey: .timestamp) {
            return Timestamp.init(
                seconds: dict["_seconds"]!,
                nanoseconds: Int32(exactly: dict["_nanoseconds"]!)!
            )
        }
        
        return try! container.decode(Timestamp.self, forKey: .timestamp)
    }
    
    static func checkMerge(
        left: MessageProtocol,
        right: MessageProtocol
    ) -> Bool {
        return left.userId == right.userId
            && abs(left.date.timeIntervalSince(right.date)) < 60 * 5 // 5 minutes interval
    }
}

extension MessageModel: MessageProtocol {
    var date: Date {
        return timestamp.dateValue()
    }
    
    var isIncoming: Bool {
        return userId != Auth.auth().currentUser!.uid
    }
    
    func forwardedKind(_ userId: String) -> [MessageModel.MessageKind] {
        var forwardedKind = kind
        if case .forward = forwardedKind.first {
            forwardedKind.remove(at: 0)
        }
        forwardedKind.insert(.forward(userId: userId), at: 0)
        return forwardedKind
    }
}

extension MessageModel: MessageTextProtocol {
    func kindText(at: Int) -> String? {
        switch kind[at] {
        case .text(let text):
            return text
        default:
            return nil
        }
    }
}

extension MessageModel: MessageImageProtocol {
    func kindImage(at: Int) -> (path: String, size: ImageSize)? {
        switch kind[at] {
        case .image(let path, let size):
            return (path: path, size: size)
        default:
            return nil
        }
    }
}

extension MessageModel: MessageAudioProtocol {
    func kindAudio(at: Int) -> String? {
        switch kind[at] {
        case .audio(let path):
            return path
        default:
            return nil
        }
    }
}

extension MessageModel: MessageForwardProtocol {
    func kindForwardUser(at: Int) -> String? {
        switch kind[at] {
        case .forward(let userId):
            return userId
        default:
            return nil
        }
    }
}
