//
//  InvoiceView.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/8/24.
//

import SwiftUI
import SwiftData

struct InvoiceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var isAddingItem = false
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var newAmount = 30.0

    private var sortedItems: [Item] {
        items.sorted { lhs, rhs in
            let lhsNotCompleted = lhs.completedDate == nil
            let rhsNotCompleted = rhs.completedDate == nil
            if lhsNotCompleted != rhsNotCompleted {
                return lhsNotCompleted
            }

            if lhs.isPaid != rhs.isPaid {
                return !lhs.isPaid
            }

            if !lhs.isPaid && !rhs.isPaid {
                return lhs.openedDate < rhs.openedDate
            }

            if lhs.isPaid && rhs.isPaid {
                let lhsCompletedDate = lhs.completedDate ?? Date.distantPast
                let rhsCompletedDate = rhs.completedDate ?? Date.distantPast
                return lhsCompletedDate > rhsCompletedDate
            }

            return false
        }
    }


    var body: some View {
        NavigationSplitView {
            List {
                ForEach(sortedItems) { item in
                    NavigationLink {
                        JobDetailView(item: item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                Text("Opened: \(item.openedDate, format: .dateTime.year().month().day())")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let completedDate = item.completedDate {
                                    Text("Completed: \(completedDate, format: .dateTime.year().month().day())")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Not Completed")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                            Spacer()
                            VStack {
                                Text(item.isPaid ? "Paid" : "Unpaid")
                                    .foregroundColor(item.isPaid ? .green : .red)
                                Text("$\(item.amount, specifier: "%.2f")")
                                    .font(.footnote)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Invoices")
            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    EditButton()
//                }
                ToolbarItem {
                    Button(action: { isAddingItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $isAddingItem) {
            addItemSheet
        }
    }

    private var addItemSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("New Job Details")) {
                    TextField("Title", text: $newTitle)
                    DatePicker("Date", selection: $newDate, displayedComponents: .date)
                    TextField("Amount", value: $newAmount, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Job")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddingItem = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addItem()
                        isAddingItem = false
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(title: newTitle, openedDate: newDate, amount: newAmount)
            modelContext.insert(newItem)
            newTitle = ""
            newDate = Date()
            newAmount = 0.0
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
//    let container = try! ModelContainer(for: Item.self)
//    let sampleItem1 = Item(title: "Unpaid Job", openedDate: Date(), completedDate: nil, isPaid: false)
//    let sampleItem2 = Item(title: "Paid Job", openedDate: Date().addingTimeInterval(-86400), completedDate: Date().addingTimeInterval(-43200), isPaid: true)
//    let sampleItem3 = Item(title: "Another Unpaid Job", openedDate: Date(), completedDate: Date(), isPaid: false)
//    container.mainContext.insert(sampleItem1)
//    container.mainContext.insert(sampleItem2)
//    container.mainContext.insert(sampleItem3)

    return InvoiceView()
//        .modelContainer(container)
}
