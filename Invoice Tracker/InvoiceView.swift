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

    private var attentionItems: [Item] {
        items
            .filter { !$0.isPaid && effectiveStatus(for: $0) != .sent }
            .sorted {
                let lhsPriority = effectiveStatus(for: $0) == .draft ? 0 : 1
                let rhsPriority = effectiveStatus(for: $1) == .draft ? 0 : 1
                return lhsPriority == rhsPriority
                    ? $0.openedDate < $1.openedDate
                    : lhsPriority < rhsPriority
            }
    }

    private var awaitingPaymentGroups: [InvoiceMonthGroup] {
        monthGroups(for: items.filter { !$0.isPaid && effectiveStatus(for: $0) == .sent })
    }

    private var paidGroups: [InvoiceMonthGroup] {
        monthGroups(for: items.filter(\.isPaid))
    }


    var body: some View {
        NavigationSplitView {
            List {
                if !attentionItems.isEmpty {
                    Section("Needs Attention") {
                        ForEach(attentionItems) { item in
                            invoiceRow(item)
                        }
                        .onDelete { offsets in
                            deleteItems(offsets: offsets, from: attentionItems)
                        }
                    }
                }

                ForEach(awaitingPaymentGroups) { group in
                    Section("Awaiting Payment — \(monthTitle(group.month))") {
                        ForEach(group.items) { item in
                            invoiceRow(item)
                        }
                        .onDelete { offsets in
                            deleteItems(offsets: offsets, from: group.items)
                        }
                    }
                }

                ForEach(paidGroups) { group in
                    Section("Paid — \(monthTitle(group.month))") {
                        ForEach(group.items) { item in
                            invoiceRow(item)
                        }
                        .onDelete { offsets in
                            deleteItems(offsets: offsets, from: group.items)
                        }
                    }
                }
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

    private func invoiceRow(_ item: Item) -> some View {
        NavigationLink {
            JobDetailView(item: item)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.headline)
                        if item.clientDocumentEnabled == true {
                            Image(systemName: item.postStatus.systemImage)
                                .foregroundStyle(postStatusColor(item.postStatus))
                                .accessibilityLabel(item.postStatus.title)
                        }
                    }
                    Text("Opened: \(item.openedDate, format: .dateTime.year().month().day())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(item.postedDate.map { "Scheduled: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Scheduled: Not Set")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack {
                    Text(item.isPaid ? "Paid" : "Unpaid")
                        .foregroundStyle(item.isPaid ? .green : .red)
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
            let newItem = Item(
                title: newTitle,
                openedDate: newDate,
                amount: newAmount,
                notes: newNote,
                clientDocumentEnabled: true
            )
            modelContext.insert(newItem)
            newTitle = ""
            newNote = ""
            newDate = Date()
            newAmount = 40.0
        }
    }

    private func deleteItems(offsets: IndexSet, from displayedItems: [Item]) {
        withAnimation {
            for offset in offsets {
                modelContext.delete(displayedItems[offset])
            }
        }
    }

    private func effectiveStatus(for item: Item) -> PostStatus {
        guard item.clientDocumentEnabled == true else {
            return item.completedDate == nil ? .draft : .sent
        }
        return item.postStatus
    }

    private func monthGroups(for groupedItems: [Item]) -> [InvoiceMonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: groupedItems) { item in
            let date = item.completedDate ?? item.openedDate
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        }

        return grouped
            .map { month, items in
                InvoiceMonthGroup(
                    month: month,
                    items: items.sorted {
                        ($0.completedDate ?? $0.openedDate) > ($1.completedDate ?? $1.openedDate)
                    }
                )
            }
            .sorted { $0.month > $1.month }
    }

    private func monthTitle(_ month: Date) -> String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private func togglePaid(for item: Item) {
        item.isPaid.toggle()
    }

    private func postStatusColor(_ status: PostStatus) -> Color {
        switch status {
        case .draft: .secondary
        case .readyToPost: .orange
        case .sent: .green
        }
    }
}

private struct InvoiceMonthGroup: Identifiable {
    let month: Date
    let items: [Item]

    var id: Date { month }
}

#Preview {
    return InvoiceView()
}
