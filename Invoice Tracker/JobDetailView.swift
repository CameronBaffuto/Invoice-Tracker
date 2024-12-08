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
    let item: Item

    init(item: Item) {
        self.item = item
        _title = State(initialValue: item.title)
        _openedDate = State(initialValue: item.openedDate)
        _completedDate = State(initialValue: item.completedDate)
        _isPaid = State(initialValue: item.isPaid)
    }

    var body: some View {
        Form {
            Section(header: Text("Job Details")) {
                TextField("Title", text: $title)
                DatePicker("Opened Date", selection: $openedDate, displayedComponents: .date)
                DatePicker("Completed Date", selection: Binding($completedDate, default: Date()), displayedComponents: .date)
                Toggle("Paid", isOn: $isPaid)
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
        try? modelContext.save()
        dismiss()
    }

    private func daysBetweenDates(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

#Preview {
    let container = try! ModelContainer(for: Item.self)
    let sampleItem = Item(title: "Sample Job", openedDate: Date().addingTimeInterval(-86400 * 7), completedDate: Date(), isPaid: false)
    container.mainContext.insert(sampleItem)

    return JobDetailView(item: sampleItem)
        .modelContainer(container)
}
