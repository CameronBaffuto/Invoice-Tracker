//
//  ContentView.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/7/24.
//

import SwiftUI

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
        }
    }
}

#Preview {
    ContentView()
}
