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

            LogoImageProcessorView()
                .tabItem {
                    Label("Images", systemImage: "photo.on.rectangle")
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
    @AppStorage(AppPreferenceKey.senderEmail) private var senderEmail = ""
    @AppStorage(AppPreferenceKey.recipientEmail) private var recipientEmail = ""

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
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
}
