//
//  LogoImageProcessorView.swift
//  Invoice Tracker
//

import Photos
import PhotosUI
import SwiftUI

struct LogoImageProcessorView: View {
    private struct ProcessedImage: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var processedImages: [ProcessedImage] = []
    @State private var isProcessing = false
    @State private var isSaving = false
    @State private var statusMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if processedImages.isEmpty {
                    ContentUnavailableView(
                        "No Images",
                        systemImage: "photo.on.rectangle",
                        description: Text("Select photos to add the logo and save finished copies back to Photos.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(processedImages) { processedImage in
                                thumbnail(for: processedImage)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Images")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !processedImages.isEmpty {
                        Button("Clear", systemImage: "xmark") {
                            processedImages = []
                            selectedItems = []
                            statusMessage = nil
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    PhotosPicker(
                        selection: $selectedItems,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Select Photos", systemImage: "photo.badge.plus")
                    }
                    .disabled(isProcessing || isSaving)

                    Button("Save", systemImage: "square.and.arrow.down") {
                        Task {
                            await saveProcessedImages()
                        }
                    }
                    .disabled(processedImages.isEmpty || isProcessing || isSaving)
                }
            }
            .overlay {
                if isProcessing || isSaving {
                    ProgressView(isProcessing ? "Processing..." : "Saving...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.bar)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await processSelectedItems(newItems)
                }
            }
        }
    }

    private func thumbnail(for processedImage: ProcessedImage) -> some View {
        GeometryReader { proxy in
            Image(uiImage: processedImage.image)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    Button {
                        remove(processedImage)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.55))
                            .padding(6)
                    }
                    .accessibilityLabel("Remove image")
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Processed image preview")
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @MainActor
    private func processSelectedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        isProcessing = true
        statusMessage = nil
        var newImages: [ProcessedImage] = []

        for item in items {
            do {
                guard
                    let data = try await item.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else {
                    statusMessage = "One selected photo could not be loaded."
                    continue
                }

                let processedImage = try LogoImageProcessor.process(image)
                newImages.append(ProcessedImage(image: processedImage))
            } catch {
                statusMessage = error.localizedDescription
            }
        }

        processedImages = newImages
        isProcessing = false
    }

    @MainActor
    private func saveProcessedImages() async {
        guard !processedImages.isEmpty else { return }

        isSaving = true
        statusMessage = nil

        do {
            let images = processedImages.map(\.image)
            try await PhotoLibrarySaver.save(images)
            processedImages = []
            selectedItems = []
            statusMessage = images.count == 1 ? "Saved 1 image to Photos and cleared it here." : "Saved \(images.count) images to Photos and cleared them here."
            HapticsManager.shared.triggerImpact(style: .medium)
        } catch {
            statusMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func remove(_ processedImage: ProcessedImage) {
        processedImages.removeAll { $0.id == processedImage.id }

        if processedImages.isEmpty {
            selectedItems = []
        }
    }
}

private enum PhotoLibrarySaver {
    static func save(_ images: [UIImage]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw SaveError.notAuthorized
        }

        let fileURLs = try images.map { image in
            let data = try LogoImageProcessor.jpegData(for: image)
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        }

        defer {
            for fileURL in fileURLs {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        try await PHPhotoLibrary.shared().performChanges {
            for fileURL in fileURLs {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
            }
        }
    }

    enum SaveError: LocalizedError {
        case notAuthorized

        var errorDescription: String? {
            "Allow Photos access to save processed images."
        }
    }
}

#Preview {
    LogoImageProcessorView()
}
