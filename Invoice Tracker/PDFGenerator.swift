//
//  PDFGenerator.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 3/21/25.
//

import Foundation
import UIKit

struct PDFGenerator {
    static func createClientPostPDF(for job: Item) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        return renderer.pdfData { context in
            var y: CGFloat = 0

            func beginPage() {
                context.beginPage()
                y = margin
            }

            func drawText(_ text: String, attributes: [NSAttributedString.Key: Any], spacingAfter: CGFloat = 0) {
                let width = pageRect.width - (margin * 2)
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let fullHeight = ceil(attributedText.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)

                if y + fullHeight > pageRect.height - margin {
                    beginPage()
                }

                attributedText.draw(in: CGRect(x: margin, y: y, width: width, height: fullHeight))
                y += fullHeight + spacingAfter
            }

            func textHeight(_ text: String, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                return ceil(attributedText.boundingRect(
                    with: CGSize(width: pageRect.width - (margin * 2), height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)
            }

            func drawPostSection(heading: String, body: String, headingAttributes: [NSAttributedString.Key: Any], bodyAttributes: [NSAttributedString.Key: Any], spacingAfter: CGFloat = 0) {
                let headingHeight = textHeight(heading, attributes: headingAttributes)
                let bodyHeight = textHeight(body, attributes: bodyAttributes)
                let firstBodyLineHeight = (bodyAttributes[.font] as? UIFont)?.lineHeight ?? 12
                let sectionHeight = headingHeight + 8 + bodyHeight + spacingAfter
                let usablePageHeight = pageRect.height - (margin * 2)

                // Move a normal-sized section as a unit. For an unusually long
                // section, keep the heading with at least its first body line.
                if (sectionHeight <= usablePageHeight && y + sectionHeight > pageRect.height - margin)
                    || y + headingHeight + 8 + firstBodyLineHeight > pageRect.height - margin {
                    beginPage()
                }

                drawText(heading, attributes: headingAttributes, spacingAfter: 8)
                drawText(body, attributes: bodyAttributes, spacingAfter: spacingAfter)
            }

            beginPage()

            let headerWidth: CGFloat = 380
            "GGC Facebook Post".draw(
                in: CGRect(x: margin, y: y, width: headerWidth, height: 34),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 26)]
            )
            y += 40
            job.title.draw(
                in: CGRect(x: margin, y: y, width: headerWidth, height: 18),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )
            y += 20
            let documentDate = job.completedDate ?? job.openedDate
            dateFormatter.string(from: documentDate).draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )

            if let data = job.photoData, let image = UIImage(data: data) {
                let imageBounds = CGRect(x: pageRect.width - margin - 120, y: margin, width: 120, height: 100)
                image.draw(in: aspectFitRect(for: image.size, in: imageBounds))
            }

            y = max(y + 42, 164)
            let headingAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.systemRed
            ]
            let bodyStyle = NSMutableParagraphStyle()
            // Add half a line of leading for 1.5 line spacing.
            bodyStyle.lineSpacing = UIFont.systemFont(ofSize: 12).lineHeight * 0.5
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black,
                .paragraphStyle: bodyStyle
            ]

            drawPostSection(
                heading: "Share Post:",
                body: job.sharePost ?? "",
                headingAttributes: headingAttributes,
                bodyAttributes: bodyAttributes,
                spacingAfter: 24
            )
            drawPostSection(
                heading: "Main Post:",
                body: job.mainPost ?? "",
                headingAttributes: headingAttributes,
                bodyAttributes: bodyAttributes
            )
        }
    }

    static func createMonthlyInvoicePDF(month: String, jobs: [Item]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Invoice",
            kCGPDFContextAuthor: "Junipra"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 612.0
        let pageHeight = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            
            if let logoImage = UIImage(named: "Logo") {
                let logoBounds = CGRect(x: pageWidth - 120, y: 20, width: 80, height: 80)
                let logoRect = aspectFitRect(for: logoImage.size, in: logoBounds)
                logoImage.draw(in: logoRect)
            }

            var yPosition: CGFloat = 40

            // Title
            let title = "Invoice – \(month)"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            title.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: titleAttributes)

            yPosition += 40

            let numberColumnX: CGFloat = 40
            let titleColumnX: CGFloat = 72
            let dateColumnX: CGFloat = 360

            let headerFont = UIFont.boldSystemFont(ofSize: 16)
            let rowFont = UIFont.systemFont(ofSize: 14)
            let rowParagraphStyle = NSMutableParagraphStyle()
            rowParagraphStyle.lineBreakMode = .byTruncatingTail
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: rowFont,
                .paragraphStyle: rowParagraphStyle
            ]

            "#".draw(at: CGPoint(x: numberColumnX, y: yPosition), withAttributes: [.font: headerFont])
            "Item".draw(at: CGPoint(x: titleColumnX, y: yPosition), withAttributes: [.font: headerFont])
            "Posted Date".draw(at: CGPoint(x: dateColumnX, y: yPosition), withAttributes: [.font: headerFont])

            yPosition += 30

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            for (index, job) in jobs.enumerated() {
                let dateString = postedDateString(for: job, formatter: dateFormatter)
                let titleRect = CGRect(x: titleColumnX, y: yPosition, width: 260, height: 18)

                "\(index + 1).".draw(at: CGPoint(x: numberColumnX, y: yPosition), withAttributes: rowAttributes)
                job.title.draw(in: titleRect, withAttributes: rowAttributes)
                dateString.draw(at: CGPoint(x: dateColumnX, y: yPosition), withAttributes: rowAttributes)

                yPosition += 24
            }

            yPosition += 10
            let total = jobs.reduce(0) { $0 + $1.amount }
            let totalFont = UIFont.boldSystemFont(ofSize: 18)
            let totalAttributes: [NSAttributedString.Key: Any] = [.font: totalFont]
            let summaryLines = summaryLines(for: jobs, total: total)

            for line in summaryLines {
                let lineWidth = (line as NSString).size(withAttributes: totalAttributes).width
                let lineX = pageWidth - lineWidth - 40
                line.draw(at: CGPoint(x: lineX, y: yPosition), withAttributes: totalAttributes)
                yPosition += 24
            }

        }

        return data
    }

    private static func summaryLines(for jobs: [Item], total: Double) -> [String] {
        let totalString = currencyString(for: total)

        guard !jobs.isEmpty else {
            return ["Total: \(totalString)"]
        }

        let groupedAmounts = Dictionary(grouping: jobs, by: \.amount)
            .map { amount, jobs in (amount: amount, count: jobs.count) }
            .sorted { $0.amount < $1.amount }

        let quantitySummary = groupedAmounts
            .map { "\($0.count) x \(currencyString(for: $0.amount))" }
            .joined(separator: " + ")

        return [quantitySummary, "Total: \(totalString)"]
    }

    private static func currencyString(for amount: Double) -> String {
        String(format: "$%.2f", amount)
    }

    private static func postedDateString(for job: Item, formatter: DateFormatter) -> String {
        guard let postedDate = job.postedDate else {
            return "Not Set"
        }

        return formatter.string(from: postedDate)
    }

    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return bounds
        }

        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        let x = bounds.midX - width / 2
        let y = bounds.midY - height / 2

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
