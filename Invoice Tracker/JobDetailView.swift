//
//  JobDetailView.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import SwiftUI
import SwiftData
import PhotosUI

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
    @State private var sharePost: String
    @State private var mainPost: String
    @State private var photoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var exportedPDF: ExportedPDF?
    @State private var photoError: String?
    @State private var isSharePostExpanded = true
    @State private var isMainPostExpanded = true
    
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
        _sharePost = State(initialValue: item.sharePost ?? "")
        _mainPost = State(initialValue: item.mainPost ?? "")
        _photoData = State(initialValue: item.photoData)
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

            if item.clientDocumentEnabled == true {
                Section("Client Post") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoData == nil ? "Choose Photo" : "Replace Photo", systemImage: "photo")
                    }

                    if let photoData, let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .accessibilityLabel("Client post photo")

                        Button("Remove Photo", role: .destructive) {
                            self.photoData = nil
                            selectedPhoto = nil
                        }
                    }

                    if let photoError {
                        Text(photoError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    DisclosureGroup(isExpanded: $isSharePostExpanded) {
                        TextEditor(text: $sharePost)
                            .frame(minHeight: 120)
                    } label: {
                        postEditorHeader(title: "Share Post", text: sharePost)
                    }

                    DisclosureGroup(isExpanded: $isMainPostExpanded) {
                        TextEditor(text: $mainPost)
                            .frame(minHeight: 180)
                    } label: {
                        postEditorHeader(title: "Main Post", text: mainPost)
                    }
                }

                if completedDate != nil {
                    Section {
                        Button("Export Client PDF", systemImage: "square.and.arrow.up") {
                            exportClientPDF()
                        }
                    }
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
        .sheet(item: $exportedPDF) { pdf in
            ActivityView(activityItems: [pdf.url])
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            guard let newPhoto else { return }
            Task {
                do {
                    guard let data = try await newPhoto.loadTransferable(type: Data.self),
                          UIImage(data: data) != nil else {
                        photoError = "The selected photo could not be loaded."
                        return
                    }
                    photoData = compressedPhotoData(from: data)
                    photoError = nil
                } catch {
                    photoError = error.localizedDescription
                }
            }
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
        if item.clientDocumentEnabled == true {
            item.sharePost = sharePost
            item.mainPost = mainPost
            item.photoData = photoData
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Unable to save job: \(error)")
        }
    }

    private func exportClientPDF() {
        item.title = title
        item.completedDate = completedDate
        item.sharePost = sharePost
        item.mainPost = mainPost
        item.photoData = photoData

        let data = PDFGenerator.createClientPostPDF(for: item)
        let safeTitle = title.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M-d-yyyy"
        let exportDate = completedDate ?? openedDate
        let dateString = dateFormatter.string(from: exportDate)
        let fileTitle = safeTitle.isEmpty ? "Untitled" : safeTitle
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GGC_FBPost_\(fileTitle)_\(dateString).pdf")

        do {
            try data.write(to: url, options: .atomic)
            exportedPDF = ExportedPDF(url: url)
        } catch {
            assertionFailure("Unable to write PDF: \(error)")
        }
    }

    private func compressedPhotoData(from data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maximumDimension: CGFloat = 1_600
        let scale = min(1, maximumDimension / max(image.size.width, image.size.height))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resizedImage.jpegData(compressionQuality: 0.82) ?? data
    }

    private func postEditorHeader(title: String, text: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                UIPasteboard.general.string = text
                HapticsManager.shared.triggerImpact(style: .medium)
            } label: {
                Image(systemName: "doc.on.doc")
                    .padding(8)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Copy \(title.lowercased())")
            .buttonStyle(.borderless)
        }
    }

    private func daysBetweenDates(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct ExportedPDF: Identifiable {
    let id = UUID()
    let url: URL
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
