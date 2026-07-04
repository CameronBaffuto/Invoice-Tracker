//
//  Item.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import Foundation
import SwiftData

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
    @Attribute(.externalStorage) var photoData: Data?

    init(title: String, openedDate: Date, completedDate: Date? = nil, isPaid: Bool = false, amount: Double = 40.0, postedDate: Date? = nil, notes: String? = nil, clientDocumentEnabled: Bool? = nil, sharePost: String? = nil, mainPost: String? = nil, photoData: Data? = nil) {
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
        self.photoData = photoData
    }
}
