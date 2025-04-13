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

    init(title: String, openedDate: Date, completedDate: Date? = nil, isPaid: Bool = false, amount: Double = 40.0, postedDate: Date? = nil, notes: String? = nil) {
        self.title = title
        self.openedDate = openedDate
        self.completedDate = completedDate
        self.isPaid = isPaid
        self.amount = amount
        self.postedDate = postedDate
        self.notes = notes
    }
}
