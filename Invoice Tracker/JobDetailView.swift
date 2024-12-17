//
//  JobDetailView.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import SwiftUI
import SwiftData

struct JobDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var openedDate: Date
    @State private var completedDate: Date?
    @State private var isPaid: Bool
    @State private var amount: Double
    
    let item: Item

    init(item: Item) {
        self.item = item
        _title = State(initialValue: item.title)
        _openedDate = State(initialValue: item.openedDate)
        _completedDate = State(initialValue: item.completedDate)
        _isPaid = State(initialValue: item.isPaid)
        _amount = State(initialValue: item.amount)
    }

    var body: some View {
        Form {
            Section(header: Text("Job Details")) {
                if #available(iOS 18.0, *) {
                    TextField("Title", text: $title)
                        .writingToolsBehavior(.complete)
                } else {
                    TextField("Title", text: $title)
                }
                DatePicker("Opened Date", selection: $openedDate, displayedComponents: .date)
                DatePicker("Completed Date", selection: Binding($completedDate, default: Date()), displayedComponents: .date)
                TextField("Amount", value: $amount, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    Toggle("Paid", isOn: $isPaid)
                        .onChange(of: isPaid) {_, newValue in
                                if newValue {
                                    HapticsManager.shared.triggerImpact(style: .medium)
                                } else {
                                    HapticsManager.shared.triggerImpact(style: .light)
                                }
                            }
            }

            if let completedDate = completedDate {
                Section(header: Text("Completion Info")) {
                    Text("Opened: \(openedDate, format: .dateTime.year().month().day())")
                    Text("Completed: \(completedDate, format: .dateTime.year().month().day())")
                    Text("Days to Complete: \(daysBetweenDates(openedDate, completedDate))")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .navigationTitle("Edit Job")
    }

    private func saveChanges() {
        item.title = title
        item.openedDate = openedDate
        item.completedDate = completedDate
        item.isPaid = isPaid
        item.amount = amount
        try? modelContext.save()
        dismiss()
    }

    private func daysBetweenDates(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
