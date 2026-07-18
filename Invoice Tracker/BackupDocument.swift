import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct InvoiceTrackerBackup: Codable {
    static let currentVersion = 1

    let version: Int
    let createdAt: Date
    let jobs: [JobBackup]

    init(items: [Item]) {
        version = Self.currentVersion
        createdAt = Date()
        jobs = items.map(JobBackup.init)
    }
}

struct JobBackup: Codable {
    let id: UUID
    let title: String
    let openedDate: Date
    let completedDate: Date?
    let isPaid: Bool
    let amount: Double
    let postedDate: Date?
    let notes: String?
    let clientDocumentEnabled: Bool?
    let sharePost: String?
    let mainPost: String?
    let postStatusRaw: String?
    let photoData: Data?

    init(item: Item) {
        id = item.id
        title = item.title
        openedDate = item.openedDate
        completedDate = item.completedDate
        isPaid = item.isPaid
        amount = item.amount
        postedDate = item.postedDate
        notes = item.notes
        clientDocumentEnabled = item.clientDocumentEnabled
        sharePost = item.sharePost
        mainPost = item.mainPost
        postStatusRaw = item.postStatusRaw
        photoData = item.photoData
    }

    func apply(to item: Item) {
        item.title = title
        item.openedDate = openedDate
        item.completedDate = completedDate
        item.isPaid = isPaid
        item.amount = amount
        item.postedDate = postedDate
        item.notes = notes
        item.clientDocumentEnabled = clientDocumentEnabled
        item.sharePost = sharePost
        item.mainPost = mainPost
        item.postStatusRaw = postStatusRaw
        item.photoData = photoData
    }

    func makeItem() -> Item {
        Item(
            id: id,
            title: title,
            openedDate: openedDate,
            completedDate: completedDate,
            isPaid: isPaid,
            amount: amount,
            postedDate: postedDate,
            notes: notes,
            clientDocumentEnabled: clientDocumentEnabled,
            sharePost: sharePost,
            mainPost: mainPost,
            postStatusRaw: postStatusRaw,
            photoData: photoData
        )
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum BackupCoding {
    static func encode(items: [Item]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(InvoiceTrackerBackup(items: items))
    }

    static func decode(data: Data) throws -> InvoiceTrackerBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(InvoiceTrackerBackup.self, from: data)
        guard backup.version <= InvoiceTrackerBackup.currentVersion else {
            throw BackupError.unsupportedVersion(backup.version)
        }
        return backup
    }
}

enum BackupError: LocalizedError {
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "This backup uses unsupported version \(version). Update the app and try again."
        }
    }
}
