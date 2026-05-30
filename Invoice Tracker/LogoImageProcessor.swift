//
//  LogoImageProcessor.swift
//  Invoice Tracker
//

import UIKit

enum LogoImageProcessor {
    enum ProcessingError: LocalizedError {
        case missingLogo
        case invalidImageSize
        case jpegExportFailed

        var errorDescription: String? {
            switch self {
            case .missingLogo:
                "Add an image to the GGC asset before processing photos."
            case .invalidImageSize:
                "The selected image has an invalid size."
            case .jpegExportFailed:
                "The processed image could not be exported."
            }
        }
    }

    private static let logoSizeRatio: CGFloat = 0.22
    private static let marginRatio: CGFloat = 0.015
    private static let jpegCompressionQuality: CGFloat = 0.92

    static func process(_ image: UIImage) throws -> UIImage {
        guard let logo = UIImage(named: "GGC") else {
            throw ProcessingError.missingLogo
        }
        let trimmedLogo = logo.trimmingTransparentOrWhiteEdges() ?? logo
        let normalizedImage = image.normalizedForProcessing()

        let imageSize = normalizedImage.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            throw ProcessingError.invalidImageSize
        }

        let shortSide = min(imageSize.width, imageSize.height)
        let logoLength = shortSide * logoSizeRatio
        let logoBounds = CGSize(width: logoLength, height: logoLength)
        let logoSize = aspectFitSize(for: trimmedLogo.size, in: logoBounds)
        let margin = shortSide * marginRatio
        let logoOrigin = CGPoint(
            x: imageSize.width - logoSize.width - margin,
            y: imageSize.height - logoSize.height - margin
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        return renderer.image { _ in
            normalizedImage.draw(in: CGRect(origin: .zero, size: imageSize))
            trimmedLogo.draw(in: CGRect(origin: logoOrigin, size: logoSize))
        }
    }

    static func jpegData(for image: UIImage) throws -> Data {
        guard let data = image.jpegData(compressionQuality: jpegCompressionQuality) else {
            throw ProcessingError.jpegExportFailed
        }

        return data
    }

    private static func aspectFitSize(for imageSize: CGSize, in bounds: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return bounds
        }

        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}

private extension UIImage {
    func normalizedForProcessing() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func trimmingTransparentOrWhiteEdges() -> UIImage? {
        guard let cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var foundContent = false

        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * bytesPerPixel
                let red = pixels[index]
                let green = pixels[index + 1]
                let blue = pixels[index + 2]
                let alpha = pixels[index + 3]

                if alpha > 10 && !(red > 245 && green > 245 && blue > 245) {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                    foundContent = true
                }
            }
        }

        guard foundContent else { return nil }

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        guard let croppedImage = cgImage.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: croppedImage, scale: scale, orientation: imageOrientation)
    }
}
