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

    @State private var showDollarAmounts = false

    private var totalPaidAmount: Double {
        items.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalUnpaidAmount: Double {
        items.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyPaidData: [(String, Double)] {
        let paidInvoices = items.filter { $0.isPaid }
        var groupedByMonth: [String: Double] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        for invoice in paidInvoices {
            let invoiceDate = invoice.completedDate ?? invoice.openedDate
            let monthString = dateFormatter.string(from: invoiceDate)
            groupedByMonth[monthString, default: 0.0] += invoice.amount
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

    private var totalPaidInvoices: Int {
        items.filter { $0.isPaid }.count
    }
    
    private var totalUnpaidInvoices: Int {
        items.filter { !$0.isPaid }.count
    }

    private var monthlyPaidInvoices: [(String, Int)] {
        let paidInvoices = items.filter { $0.isPaid }
        var groupedByMonth: [String: Int] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

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

                Section(header: Text("Monthly Data")) {
                    if showDollarAmounts {
                        ForEach(monthlyPaidData, id: \.0) { month, amount in
                            HStack {
                                Text(month)
                                Spacer()
                                Text("$\(amount, specifier: "%.2f")")
                                    .fontWeight(.bold)
                            }
                        }
                    } else {
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

