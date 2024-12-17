//
//  HiQrResult.swift
//  feat_qr
//
//  Created by netcanis on 12/17/24.
//

import Foundation

/// A class representing the result of a QR code scan.
public class HiQrResult {
    /// The scanned data.
    public let data: String

    /// An error message, if any.
    public let error: String

    /// Initializes a `HiQrResult` object with scanned QR data and an optional error message.
    /// - Parameters:
    ///   - qrData: The scanned data string from the QR code.
    ///   - error: An optional error message (default is an empty string).
    public init(qrData: String, error: String = "") {
        self.data = qrData
        self.error = error
    }
}
