//
//  ContentView.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        TabView {
            InvoiceView()
                .tabItem {
                    Label("Invoices", systemImage: "list.bullet")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

enum AppPreferenceKey {
    static let senderEmail = "emailExport.senderAddress"
    static let recipientEmail = "emailExport.recipientAddress"
}

private struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @AppStorage(AppPreferenceKey.senderEmail) private var senderEmail = ""
    @AppStorage(AppPreferenceKey.recipientEmail) private var recipientEmail = ""
    @State private var backupDocument = BackupDocument(data: Data())
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var pendingBackup: InvoiceTrackerBackup?
    @State private var backupMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Sender email", text: $senderEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Recipient email", text: $recipientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("PDF Email Export")
                } footer: {
                    Text("The sender must be an account configured in iOS Mail. These addresses are stored only in this app's local settings.")
                }

                Section {
                    Button("Export Backup", systemImage: "square.and.arrow.up") {
                        exportBackup()
                    }

                    Button("Import Backup", systemImage: "square.and.arrow.down") {
                        isImportingBackup = true
                    }
                } header: {
                    Text("Backup & Restore")
                } footer: {
                    Text("Exports all \(items.count) jobs and their photos as a versioned JSON file. Import merges records by ID and never deletes local jobs.")
                }
            }
            .navigationTitle("Settings")
        }
        .fileExporter(
            isPresented: $isExportingBackup,
            document: backupDocument,
            contentType: .json,
            defaultFilename: backupFilename
        ) { result in
            switch result {
            case .success:
                backupMessage = "Backup exported successfully."
            case .failure(let error):
                backupMessage = "The backup could not be exported: \(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $isImportingBackup, allowedContentTypes: [.json]) { result in
            importBackup(from: result)
        }
        .alert("Import Backup?", isPresented: hasPendingBackup) {
            Button("Cancel", role: .cancel) {
                pendingBackup = nil
            }
            Button("Import") {
                mergePendingBackup()
            }
        } message: {
            Text("This will add missing jobs and update matching jobs from the backup. It will not delete any local jobs.")
        }
        .alert("Backup & Restore", isPresented: hasBackupMessage) {
            Button("OK", role: .cancel) {
                backupMessage = nil
            }
        } message: {
            Text(backupMessage ?? "")
        }
    }

    private var backupFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "Invoice-Tracker-Backup-\(formatter.string(from: Date()))"
    }

    private var hasPendingBackup: Binding<Bool> {
        Binding(
            get: { pendingBackup != nil },
            set: { if !$0 { pendingBackup = nil } }
        )
    }

    private var hasBackupMessage: Binding<Bool> {
        Binding(
            get: { backupMessage != nil },
            set: { if !$0 { backupMessage = nil } }
        )
    }

    private func exportBackup() {
        do {
            backupDocument = BackupDocument(data: try BackupCoding.encode(items: items))
            isExportingBackup = true
        } catch {
            backupMessage = "The backup could not be created: \(error.localizedDescription)"
        }
    }

    private func importBackup(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            pendingBackup = try BackupCoding.decode(data: Data(contentsOf: url))
        } catch {
            backupMessage = "The backup could not be read: \(error.localizedDescription)"
        }
    }

    private func mergePendingBackup() {
        guard let backup = pendingBackup else { return }
        let existingItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var addedCount = 0
        var updatedCount = 0

        for job in backup.jobs {
            if let item = existingItems[job.id] {
                job.apply(to: item)
                updatedCount += 1
            } else {
                modelContext.insert(job.makeItem())
                addedCount += 1
            }
        }

        do {
            try modelContext.save()
            pendingBackup = nil
            backupMessage = "Import complete: \(addedCount) added and \(updatedCount) updated."
        } catch {
            backupMessage = "The imported jobs could not be saved: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}
