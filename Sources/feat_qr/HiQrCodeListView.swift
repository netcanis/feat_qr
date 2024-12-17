//
//  HiQrCodeListView.swift
//  feat_qr
//
//  Created by netcanis on 11/20/24.
//

import SwiftUI

/// A SwiftUI View for displaying QR code scan results.
/// - Shows a list of scanned dates and QR codes.
public struct HiQrCodeListView: View {
    /// An array to store scanned QR codes along with their corresponding scan dates.
    @State private var codes: [(date: Date, code: String)] = []
    /// Dismisses the current view when required.
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization
    public init() {}

    // MARK: - View Body
    public var body: some View {
        VStack {
            // List displaying scanned QR codes and their timestamps
            List(codes, id: \.code) { result in
                VStack(alignment: .leading) {
                    Text("Scanned Date: \(result.date.formatted())")
                    Text("QR Code: \(result.code)")
                }
            }
            .navigationTitle("QR Code Scans") // Sets the navigation title
            .navigationBarTitleDisplayMode(.inline) // Centers the navigation title
            .onAppear(perform: startQrScan) // Starts scanning when the view appears
            .onDisappear { HiQrScanner.shared.stop() } // Stops scanning when the view disappears
        }
    }

    /// Starts QR code scanning.
    /// - Updates the scanned code if it already exists or adds it if new.
    private func startQrScan() {
        HiQrScanner.shared.start { result in
            let qrCode = result.data

            // Check if the scanned QR code is already in the list
            if let index = codes.firstIndex(where: { $0.code == qrCode }) {
                // Update the timestamp of the existing QR code
                codes[index] = (date: Date(), code: qrCode)
                print("Updated QR Code: \(qrCode)")
            } else {
                // Append new QR code to the list
                codes.append((date: Date(), code: qrCode))
                print("Added new QR Code: \(qrCode)")
            }
        }
    }
}

#Preview {
    HiQrCodeListView()
}
