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

    private var totalPaidInvoices: Int {
        items.filter { $0.isPaid }.count
    }

    private var monthlyPaidInvoices: [(String, Int)] {
        let paidInvoices = items.filter { $0.isPaid }
        var groupedByMonth: [String: Int] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        let reverseFormatter = DateFormatter()
        reverseFormatter.dateFormat = "yyyy-MM"

        for invoice in paidInvoices {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let monthString = dateFormatter.string(from: invoiceDate)
            groupedByMonth[monthString, default: 0] += 1
        }

        return groupedByMonth.sorted { lhs, rhs in
            guard
                let lhsDate = dateFormatter.date(from: lhs.key),
                let rhsDate = dateFormatter.date(from: rhs.key)
            else {
                return lhs.key > rhs.key
            }
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("All Time")) {
                    HStack {
                        Text("Total Paid Invoices")
                        Spacer()
                        Text("\(totalPaidInvoices)")
                            .fontWeight(.bold)
                    }
                }

                // Month-by-Month Data
                Section(header: Text("Month by Month Data")) {
                    ForEach(monthlyPaidInvoices, id: \.0) { month, count in
                        HStack {
                            Text(month)
                            Spacer()
                            Text("\(count)")
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            .navigationTitle("Insights")
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

