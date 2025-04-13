//
//  PDFGenerator.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 3/21/25.
//

import Foundation
import PDFKit
import UIKit

struct PDFGenerator {
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
                let logoRect = CGRect(x: pageWidth - 140, y: 20, width: 100, height: 40)
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

            // Job rows
            let _: CGFloat = 24

            let column1X: CGFloat = 40   // Job Title
            let column2X: CGFloat = 250  // Date
            let column3X: CGFloat = 450  // Amount

            let headerFont = UIFont.boldSystemFont(ofSize: 16)
            let rowFont = UIFont.systemFont(ofSize: 14)

            "Job Title".draw(at: CGPoint(x: column1X, y: yPosition), withAttributes: [.font: headerFont])
            "Posted Date".draw(at: CGPoint(x: column2X, y: yPosition), withAttributes: [.font: headerFont])
            "Amount".draw(at: CGPoint(x: column3X, y: yPosition), withAttributes: [.font: headerFont])

            yPosition += 30

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short

            for job in jobs {
                let date: Date

                if job.completedDate != nil {
                    date = job.postedDate ?? job.completedDate!
                } else {
                    date = job.openedDate
                }

                let dateString = dateFormatter.string(from: date)
                let amountString = String(format: "%.2f", job.amount)

                job.title.draw(at: CGPoint(x: column1X, y: yPosition), withAttributes: [.font: rowFont])
                dateString.draw(at: CGPoint(x: column2X, y: yPosition), withAttributes: [.font: rowFont])
                "$\(amountString)".draw(at: CGPoint(x: column3X, y: yPosition), withAttributes: [.font: rowFont])

                yPosition += 24
            }

            yPosition += 10
            let total = jobs.reduce(0) { $0 + $1.amount }
            let totalString = String(format: "%.2f", total)
            let totalLine = "Total: $\(totalString)"
            let totalFont = UIFont.boldSystemFont(ofSize: 18)
            let totalAttributes: [NSAttributedString.Key: Any] = [.font: totalFont]
            let totalLineWidth = (totalLine as NSString).size(withAttributes: totalAttributes).width
            let totalX = pageWidth - totalLineWidth - 40

            totalLine.draw(at: CGPoint(x: totalX, y: yPosition), withAttributes: totalAttributes)

        }

        return data
    }
}
