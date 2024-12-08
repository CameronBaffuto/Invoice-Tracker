//
//  Binding+Extensions.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import Foundation
import SwiftUI

extension Binding {
    init(_ source: Binding<Value?>, default defaultValue: Value) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}
