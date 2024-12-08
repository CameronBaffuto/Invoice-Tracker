//
//  Item.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String
    var openedDate: Date
    var completedDate: Date?
    var isPaid: Bool

    init(title: String, openedDate: Date, completedDate: Date? = nil, isPaid: Bool = false) {
        self.title = title
        self.openedDate = openedDate
        self.completedDate = completedDate
        self.isPaid = isPaid
    }
}
