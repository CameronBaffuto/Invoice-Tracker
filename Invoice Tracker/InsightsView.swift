//
//  InsightsView.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/8/24.
//


import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var items: [Item]

    @State private var showDollarAmounts = true

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private var totalPaidAmount: Double {
        items.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalUnpaidAmount: Double {
        items.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyPaidData: [(String, Double)] {
        let paidInvoices = items.filter { $0.isPaid }
        var groupedByMonth: [String: Double] = [:]

        for invoice in paidInvoices {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let monthString = Self.monthFormatter.string(from: invoiceDate)
            groupedByMonth[monthString, default: 0.0] += invoice.amount
        }

        return groupedByMonth.sorted { lhs, rhs in
            guard
                let lhsDate = Self.monthFormatter.date(from: lhs.key),
                let rhsDate = Self.monthFormatter.date(from: rhs.key)
            else {
                return lhs.key > rhs.key
            }
            return lhsDate > rhsDate
        }
    }

    private var monthlyAllData: [(String, Double)] {
        var groupedByMonth: [String: Double] = [:]

        for invoice in items {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let monthString = Self.monthFormatter.string(from: invoiceDate)
            groupedByMonth[monthString, default: 0.0] += invoice.amount
        }

        return groupedByMonth.sorted { lhs, rhs in
            guard
                let lhsDate = Self.monthFormatter.date(from: lhs.key),
                let rhsDate = Self.monthFormatter.date(from: rhs.key)
            else {
                return lhs.key > rhs.key
            }
            return lhsDate > rhsDate
        }
    }

    private var yearlyPaidData: [(String, Double)] {
        let paidInvoices = items.filter { $0.isPaid }
        var groupedByYear: [String: Double] = [:]

        for invoice in paidInvoices {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let yearString = Self.yearFormatter.string(from: invoiceDate)
            groupedByYear[yearString, default: 0.0] += invoice.amount
        }

        return groupedByYear.sorted { lhs, rhs in
            guard
                let lhsYear = Int(lhs.key),
                let rhsYear = Int(rhs.key)
            else {
                return lhs.key > rhs.key
            }
            return lhsYear > rhsYear
        }
    }

    private var totalPaidInvoices: Int {
        items.filter { $0.isPaid }.count
    }
    
    private var totalUnpaidInvoices: Int {
        items.filter { !$0.isPaid }.count
    }

    private var monthlyPaidInvoices: [(String, Int)] {
        let paidInvoices = items.filter { $0.isPaid }
        var groupedByMonth: [String: Int] = [:]

        for invoice in paidInvoices {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let monthString = Self.monthFormatter.string(from: invoiceDate)
            groupedByMonth[monthString, default: 0] += 1
        }

        return groupedByMonth.sorted { lhs, rhs in
            guard
                let lhsDate = Self.monthFormatter.date(from: lhs.key),
                let rhsDate = Self.monthFormatter.date(from: rhs.key)
            else {
                return lhs.key > rhs.key
            }
            return lhsDate > rhsDate
        }
    }

    private var monthlyAllInvoices: [(String, Int)] {
        var groupedByMonth: [String: Int] = [:]

        for invoice in items {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let monthString = Self.monthFormatter.string(from: invoiceDate)
            groupedByMonth[monthString, default: 0] += 1
        }

        return groupedByMonth.sorted { lhs, rhs in
            guard
                let lhsDate = Self.monthFormatter.date(from: lhs.key),
                let rhsDate = Self.monthFormatter.date(from: rhs.key)
            else {
                return lhs.key > rhs.key
            }
            return lhsDate > rhsDate
        }
    }

    private var yearlyPaidInvoices: [(String, Int)] {
        let paidInvoices = items.filter { $0.isPaid }
        var groupedByYear: [String: Int] = [:]

        for invoice in paidInvoices {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let yearString = Self.yearFormatter.string(from: invoiceDate)
            groupedByYear[yearString, default: 0] += 1
        }

        return groupedByYear.sorted { lhs, rhs in
            guard
                let lhsYear = Int(lhs.key),
                let rhsYear = Int(rhs.key)
            else {
                return lhs.key > rhs.key
            }
            return lhsYear > rhsYear
        }
    }

    private var currentMonthKey: String {
        Self.monthFormatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("All Time")) {
                    HStack {
                        Text("Total Paid")
                        Spacer()
                        if showDollarAmounts {
                            Text("$\(totalPaidAmount, specifier: "%.2f")")
                                .fontWeight(.bold)
                        } else {
                            Text("\(totalPaidInvoices)")
                                .fontWeight(.bold)
                        }
                    }
                    HStack {
                        Text("Total Unpaid")
                        Spacer()
                        if showDollarAmounts {
                            Text("$\(totalUnpaidAmount, specifier: "%.2f")")
                                .fontWeight(.bold)
                        } else {
                            Text("\(totalUnpaidInvoices)")
                                    .fontWeight(.bold)
                        }
                    }
                }

                Section(header: Text("Paid by Year")) {
                    if showDollarAmounts {
                        ForEach(yearlyPaidData, id: \.0) { year, amount in
                            HStack {
                                Text(year)
                                Spacer()
                                Text("$\(amount, specifier: "%.2f")")
                                    .fontWeight(.bold)
                            }
                        }
                    } else {
                        ForEach(yearlyPaidInvoices, id: \.0) { year, count in
                            HStack {
                                Text(year)
                                Spacer()
                                Text("\(count)")
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }

                Section(header: Text("Monthly Data")) {
                    if showDollarAmounts {
                        let paidLookup = Dictionary(monthlyPaidData, uniquingKeysWith: { $1 })
                        let allLookup = Dictionary(monthlyAllData, uniquingKeysWith: { $1 })
                        ForEach(monthlyAllData, id: \.0) { month, _ in
                            let isCurrentMonth = month == currentMonthKey
                            let amount = isCurrentMonth ? (allLookup[month] ?? 0) : (paidLookup[month] ?? 0)
                            HStack {
                                Text(month)
                                    .foregroundColor(isCurrentMonth ? .red : .primary)
                                Spacer()
                                Text("$\(amount, specifier: "%.2f")")
                                    .fontWeight(.bold)
                                    .foregroundColor(isCurrentMonth ? .red : .primary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    exportPDF(for: month)
                                } label: {
                                    Label("Export", systemImage: "arrow.down.doc")
                                }
                                .tint(.blue)
                            }
                        }
                    } else {
                        let paidLookup = Dictionary(monthlyPaidInvoices, uniquingKeysWith: { $1 })
                        let allLookup = Dictionary(monthlyAllInvoices, uniquingKeysWith: { $1 })
                        ForEach(monthlyAllInvoices, id: \.0) { month, _ in
                            let isCurrentMonth = month == currentMonthKey
                            let count = isCurrentMonth ? (allLookup[month] ?? 0) : (paidLookup[month] ?? 0)
                            HStack {
                                Text(month)
                                    .foregroundColor(isCurrentMonth ? .red : .primary)
                                Spacer()
                                Text("\(count)")
                                    .fontWeight(.bold)
                                    .foregroundColor(isCurrentMonth ? .red : .primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showDollarAmounts.toggle()
                        HapticsManager.shared.triggerSelection()
                    }) {
                        Image(systemName: showDollarAmounts ? "number.square" : "dollarsign.square")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel("Toggle between dollar amounts and counts")
                }
            }
        }
    }
    
    func exportPDF(for month: String) {
        let filteredJobs = items.filter { item in
            let date = item.completedDate ?? item.openedDate
            return Self.monthFormatter.string(from: date) == month
        }

        let pdfData = PDFGenerator.createMonthlyInvoicePDF(month: month, jobs: filteredJobs)
        let safeMonth = month.replacingOccurrences(of: " ", with: "")
        let fileName = "Invoice\(safeMonth).pdf"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: tempURL)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
}



#Preview {
    let container = try! ModelContainer(for: Item.self)
    let sampleItem1 = Item(title: "Paid in Nov", openedDate: Date().addingTimeInterval(-86400 * 40), completedDate: Date().addingTimeInterval(-86400 * 30), isPaid: true)
    let sampleItem2 = Item(title: "Paid in Dec", openedDate: Date().addingTimeInterval(-86400 * 20), completedDate: Date().addingTimeInterval(-86400 * 10), isPaid: true)
    let sampleItem3 = Item(title: "Unpaid Job", openedDate: Date(), completedDate: nil, isPaid: false)
    let sampleItem4 = Item(title: "Paid in Dec", openedDate: Date().addingTimeInterval(-86400 * 15), completedDate: Date().addingTimeInterval(-86400 * 5), isPaid: true)
    let sampleItem5 = Item(title: "Paid in Jan", openedDate: Date().addingTimeInterval(-86400 * 5), completedDate: Date(), isPaid: true)
    container.mainContext.insert(sampleItem1)
    container.mainContext.insert(sampleItem2)
    container.mainContext.insert(sampleItem3)
    container.mainContext.insert(sampleItem4)
    container.mainContext.insert(sampleItem5)

    return InsightsView()
        .modelContainer(container)
}
