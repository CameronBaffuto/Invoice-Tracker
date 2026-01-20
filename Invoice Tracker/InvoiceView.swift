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
    @State private var newNote = ""
    @State private var newDate = Date()
    @State private var newAmount = 40.0

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
                                if let postedDate = item.postedDate {
                                    HStack(spacing: 6) {
                                        Text("Posted: \(postedDate, format: .dateTime.year().month().day().hour().minute())")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        if item.completedDate != nil {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(.gray)
                                                .accessibilityLabel("Completed")
                                        }
                                    }
                                } else {
                                    Text("Posted: Not Set")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
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
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            togglePaid(for: item)
                        } label: {
                            Label(item.isPaid ? "Mark Unpaid" : "Mark Paid", systemImage: "checkmark.seal")
                        }
                        .tint(item.isPaid ? .orange : .green)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
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
                    if #available(iOS 18.0, *) {
                        TextField("Title", text: $newTitle)
                            .writingToolsBehavior(.complete)
                    } else {
                        TextField("Title", text: $newTitle)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $newNote)
                            .frame(height: 150)
                            .padding(4)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }

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
            let newItem = Item(title: newTitle, openedDate: newDate, amount: newAmount, notes: newNote)
            modelContext.insert(newItem)
            newTitle = ""
            newNote = ""
            newDate = Date()
            newAmount = 40.0
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let itemsToDelete = offsets.map { sortedItems[$0] }
            for item in itemsToDelete {
                if let originalIndex = items.firstIndex(where: { $0.id == item.id }) {
                    modelContext.delete(items[originalIndex])
                }
            }
        }
    }

    private func togglePaid(for item: Item) {
        item.isPaid.toggle()
    }
}

#Preview {
    return InvoiceView()
}
