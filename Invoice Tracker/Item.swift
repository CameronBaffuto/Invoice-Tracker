//
//  Item.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import Foundation
import SwiftData

enum PostStatus: String, CaseIterable, Identifiable {
    case draft
    case readyToPost
    case sent

    var id: Self { self }

    var title: String {
        switch self {
        case .draft: "Draft"
        case .readyToPost: "Ready to Send"
        case .sent: "Sent"
        }
    }

    var systemImage: String {
        switch self {
        case .draft: "doc.text"
        case .readyToPost: "checkmark.circle"
        case .sent: "envelope.badge"
        }
    }
}

@Model
final class Item: Identifiable {
    var id = UUID()
    var title: String
    var openedDate: Date
    var completedDate: Date?
    var isPaid: Bool
    var amount: Double
    var postedDate: Date?
    var notes: String?
    // Optional for migration safety: existing jobs remain nil and do not gain the
    // client-document workflow. Newly created jobs explicitly set this to true.
    var clientDocumentEnabled: Bool?
    var sharePost: String?
    var mainPost: String?
    // Optional so existing stores migrate without rewriting legacy jobs.
    var postStatusRaw: String?
    @Attribute(.externalStorage) var photoData: Data?

    init(id: UUID = UUID(), title: String, openedDate: Date, completedDate: Date? = nil, isPaid: Bool = false, amount: Double = 40.0, postedDate: Date? = nil, notes: String? = nil, clientDocumentEnabled: Bool? = nil, sharePost: String? = nil, mainPost: String? = nil, postStatusRaw: String? = PostStatus.draft.rawValue, photoData: Data? = nil) {
        self.id = id
        self.title = title
        self.openedDate = openedDate
        self.completedDate = completedDate
        self.isPaid = isPaid
        self.amount = amount
        self.postedDate = postedDate
        self.notes = notes
        self.clientDocumentEnabled = clientDocumentEnabled
        self.sharePost = sharePost
        self.mainPost = mainPost
        self.postStatusRaw = postStatusRaw
        self.photoData = photoData
    }
}

extension Item {
    var postStatus: PostStatus {
        get {
            // Preserve compatibility with the short-lived four-state workflow.
            if postStatusRaw == "posted" {
                return .sent
            }
            if let postStatusRaw, let status = PostStatus(rawValue: postStatusRaw) {
                return status
            }
            return completedDate == nil ? .draft : .readyToPost
        }
        set { postStatusRaw = newValue.rawValue }
    }
}
