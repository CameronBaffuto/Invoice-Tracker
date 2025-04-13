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
    @State private var notes: String
    @State private var openedDate: Date
    @State private var completedDate: Date?
    @State private var isPaid: Bool
    @State private var amount: Double
    @State private var isCompleted: Bool
    @State private var postedDate: Date?
    
    @State private var isShowingEditor = false

    let item: Item

    init(item: Item) {
        self.item = item
        _title = State(initialValue: item.title)
        _notes = State(initialValue: item.notes ?? "")
        _openedDate = State(initialValue: item.openedDate)
        _completedDate = State(initialValue: item.completedDate)
        _isPaid = State(initialValue: item.isPaid)
        _amount = State(initialValue: item.amount)
        _isCompleted = State(initialValue: item.completedDate != nil)
        _postedDate = State(initialValue: item.postedDate)
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

                Toggle("Completed", isOn: $isCompleted)
                    .onChange(of: isCompleted) { _, newValue in
                        if newValue {
                            completedDate = Date()
                        } else {
                            completedDate = nil
                        }
                    }

                TextField("Amount", value: $amount, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)

                Toggle("Paid", isOn: $isPaid)
                    .onChange(of: isPaid) { _, newValue in
                        if newValue {
                            HapticsManager.shared.triggerImpact(style: .medium)
                        } else {
                            HapticsManager.shared.triggerImpact(style: .light)
                        }
                    }
            }

            Section(header: Text("Notes")) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(notes.isEmpty ? "Tap to add notes..." : notes)
                            .lineLimit(2)
                            .foregroundColor(notes.isEmpty ? .gray : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    isShowingEditor = true
                                }
                            }
                    }

                Button(action: {
                    UIPasteboard.general.string = notes
                    HapticsManager.shared.triggerImpact(style: .medium)
                }) {
                    Image(systemName: "doc.on.doc")
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Copy notes")
                .buttonStyle(.plain)
            }
        }


            if let completedDate = completedDate {
                Section(header: Text("Completion Info")) {
                    Text("Opened: \(openedDate, format: .dateTime.year().month().day())")
                    Text("Completed: \(completedDate, format: .dateTime.year().month().day())")
                    Text("Days to Complete: \(daysBetweenDates(openedDate, completedDate))")
                    DatePicker("Posted Date/Time", selection: Binding($postedDate, default: Date()), displayedComponents: [.date, .hourAndMinute])
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
        .sheet(isPresented: $isShowingEditor) {
            NotesEditorView(notes: $notes)
        }
    }

    private func saveChanges() {
        item.title = title
        item.notes = notes
        item.openedDate = openedDate
        item.completedDate = completedDate
        item.isPaid = isPaid
        item.amount = amount
        item.postedDate = postedDate
        try? modelContext.save()
        dismiss()
    }

    private func daysBetweenDates(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

struct NotesEditorView: View {
    @Binding var notes: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            TextEditor(text: $notes)
                .padding()
                .navigationTitle("Edit Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
