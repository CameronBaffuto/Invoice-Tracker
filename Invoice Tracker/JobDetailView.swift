//
//  JobDetailView.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import SwiftUI
import SwiftData
import PhotosUI
import MessageUI
import PDFKit

struct JobDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPreferenceKey.senderEmail) private var senderEmail = ""
    @AppStorage(AppPreferenceKey.recipientEmail) private var recipientEmail = ""
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
    @State private var postStatus: PostStatus
    @State private var photoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var exportedPDF: ExportedPDF?
    @State private var exportIssue: ExportIssue?
    @State private var photoError: String?
    @State private var isSharePostExpanded = true
    @State private var isMainPostExpanded = true
    @State private var selectedLogoPhotos: [PhotosPickerItem] = []
    @State private var isProcessingLogoPhotos = false
    @State private var imageProcessingMessage: String?
    
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
        _postStatus = State(initialValue: item.postStatus)
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
                            if postStatus == .draft {
                                postStatus = .readyToPost
                            }
                        } else {
                            completedDate = nil
                            postStatus = .draft
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

                if item.clientDocumentEnabled == true {
                    HStack {
                        Text("Workflow")
                        Spacer()
                        Menu {
                            ForEach(PostStatus.allCases) { status in
                                Button {
                                    setPostStatus(status)
                                } label: {
                                    Label(status.title, systemImage: status.systemImage)
                                }
                            }
                        } label: {
                            Label(postStatus.title, systemImage: postStatus.systemImage)
                                .foregroundStyle(postStatusColor(postStatus))
                        }
                    }
                    .frame(height: 44)
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
                            .padding(.horizontal, -12)
                    } label: {
                        postEditorHeader(title: "Share Post", text: sharePost)
                    }

                    DisclosureGroup(isExpanded: $isMainPostExpanded) {
                        TextEditor(text: $mainPost)
                            .frame(minHeight: 180)
                            .padding(.horizontal, -12)
                    } label: {
                        postEditorHeader(title: "Main Post", text: mainPost)
                    }
                }

            }


            if let completedDate = completedDate {
                Section(header: Text("Completion Info")) {
                    Text("Opened: \(openedDate, format: .dateTime.year().month().day())")
                    Text("Completed: \(completedDate, format: .dateTime.year().month().day())")
                    DatePicker("Scheduled Post Date/Time", selection: Binding($postedDate, default: Date()), displayedComponents: [.date, .hourAndMinute])
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                PhotosPicker(
                    selection: $selectedLogoPhotos,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "photo.badge.plus")
                }
                .accessibilityLabel("Add logo to images")
                .disabled(isProcessingLogoPhotos)

                if item.clientDocumentEnabled == true, completedDate != nil {
                    Button {
                        exportClientPDF()
                    } label: {
                        Image(systemName: "doc.badge.arrow.up")
                    }
                    .accessibilityLabel("Preview and export client PDF")
                }

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
            PDFPreviewScreen(export: pdf) {
                markEmailSent()
            }
        }
        .alert(item: $exportIssue) { issue in
            Alert(
                title: Text(issue.title),
                message: Text(issue.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Image Processing", isPresented: isShowingImageProcessingMessage) {
            Button("OK", role: .cancel) {
                imageProcessingMessage = nil
            }
        } message: {
            Text(imageProcessingMessage ?? "")
        }
        .overlay {
            if isProcessingLogoPhotos {
                ProgressView("Adding logo and saving...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .onChange(of: selectedLogoPhotos) { _, newPhotos in
            guard !newPhotos.isEmpty else { return }
            Task {
                await processAndSaveLogoPhotos(newPhotos)
            }
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

    private var isShowingImageProcessingMessage: Binding<Bool> {
        Binding(
            get: { imageProcessingMessage != nil },
            set: { if !$0 { imageProcessingMessage = nil } }
        )
    }

    @MainActor
    private func processAndSaveLogoPhotos(_ photos: [PhotosPickerItem]) async {
        isProcessingLogoPhotos = true
        defer {
            isProcessingLogoPhotos = false
            selectedLogoPhotos = []
        }

        do {
            var processedImages: [UIImage] = []
            for photo in photos {
                guard
                    let data = try await photo.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    throw ImageProcessingError.unreadablePhoto
                }
                processedImages.append(try LogoImageProcessor.process(image))
            }

            try await PhotoLibrarySaver.save(processedImages)
            let count = processedImages.count
            imageProcessingMessage = count == 1
                ? "Saved 1 logo image to Photos."
                : "Saved \(count) logo images to Photos."
            HapticsManager.shared.triggerImpact(style: .medium)
        } catch {
            imageProcessingMessage = "The images could not be saved: \(error.localizedDescription)"
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
            item.postStatus = postStatus
            item.photoData = photoData
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Unable to save job: \(error)")
        }
    }

    private func setPostStatus(_ status: PostStatus) {
        postStatus = status
        switch status {
        case .draft:
            isCompleted = false
            completedDate = nil
        case .readyToPost, .sent:
            isCompleted = true
            if completedDate == nil {
                completedDate = Date()
            }
        }
    }

    private func markEmailSent() {
        postStatus = .sent
        item.postStatus = .sent
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save sent status: \(error)")
        }
    }

    private func exportClientPDF() {
        let configuredSender = senderEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let configuredRecipient = recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard configuredSender.contains("@"), configuredRecipient.contains("@") else {
            exportIssue = .missingEmailSettings
            return
        }

        var missingFields: [String] = []
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Title")
        }
        if postedDate == nil {
            missingFields.append("Scheduled Post Date/Time")
        }
        if sharePost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Share Post")
        }
        if mainPost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Main Post")
        }
        guard missingFields.isEmpty else {
            exportIssue = .missingRequiredFields(missingFields)
            return
        }
        guard let postingDate = postedDate else { return }
        guard MFMailComposeViewController.canSendMail() else {
            exportIssue = .mailUnavailable
            return
        }

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
            let postingDateFormatter = DateFormatter()
            postingDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            postingDateFormatter.dateFormat = "MMM d, yyyy"
            let postingTimeFormatter = DateFormatter()
            postingTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
            postingTimeFormatter.dateFormat = "h:mma"

            exportedPDF = ExportedPDF(
                url: url,
                senderEmail: configuredSender,
                recipientEmail: configuredRecipient,
                subject: "GGC Facebook Post – \(title)",
                body: "Will be posted \(postingDateFormatter.string(from: postingDate)) at \(postingTimeFormatter.string(from: postingDate).lowercased())"
            )
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

    private func postStatusColor(_ status: PostStatus) -> Color {
        switch status {
        case .draft: .secondary
        case .readyToPost: .orange
        case .sent: .green
        }
    }

}

private struct PDFPreviewScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var emailDraft: ExportedPDF?

    let export: ExportedPDF
    let onMailSent: () -> Void

    var body: some View {
        NavigationStack {
            PDFDocumentView(url: export.url)
                .navigationTitle("PDF Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Email", systemImage: "envelope") {
                            emailDraft = export
                        }
                    }
                }
        }
        .sheet(item: $emailDraft) { draft in
            MailComposeView(export: draft, onSent: onMailSent)
        }
    }
}

private struct PDFDocumentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}

private struct MailComposeView: UIViewControllerRepresentable {
    let export: ExportedPDF
    let onSent: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSent: onSent)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setPreferredSendingEmailAddress(export.senderEmail)
        composer.setToRecipients([export.recipientEmail])
        composer.setSubject(export.subject)
        composer.setMessageBody(export.body, isHTML: false)

        if let pdfData = try? Data(contentsOf: export.url) {
            composer.addAttachmentData(
                pdfData,
                mimeType: "application/pdf",
                fileName: export.url.lastPathComponent
            )
        }

        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onSent: () -> Void

        init(onSent: @escaping () -> Void) {
            self.onSent = onSent
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if result == .sent {
                onSent()
            }
            controller.dismiss(animated: true)
        }
    }
}

private struct ExportedPDF: Identifiable {
    let id = UUID()
    let url: URL
    let senderEmail: String
    let recipientEmail: String
    let subject: String
    let body: String
}

private enum ExportIssue: Identifiable {
    case missingEmailSettings
    case missingRequiredFields([String])
    case mailUnavailable

    var id: String {
        switch self {
        case .missingEmailSettings: "missingEmailSettings"
        case .missingRequiredFields: "missingRequiredFields"
        case .mailUnavailable: "mailUnavailable"
        }
    }

    var title: String {
        switch self {
        case .missingEmailSettings: "Email Settings Required"
        case .missingRequiredFields: "Complete Required Fields"
        case .mailUnavailable: "Mail Is Not Configured"
        }
    }

    var message: String {
        switch self {
        case .missingEmailSettings:
            "Enter valid sender and recipient addresses in the Settings tab, then try again."
        case .missingRequiredFields(let fields):
            "Complete the following before exporting:\n\n\(fields.map { "• \($0)" }.joined(separator: "\n"))"
        case .mailUnavailable:
            "Add the sender account to Mail in iOS Settings, then try exporting again."
        }
    }
}

private enum ImageProcessingError: LocalizedError {
    case unreadablePhoto

    var errorDescription: String? {
        "One of the selected photos could not be loaded."
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
