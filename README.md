# **feat_qr**

A **Swift Package** for QR Code scanning on iOS, including features like customizable UI overlays and scan callbacks.

---

## **Overview**

`feat_qr` is a lightweight Swift package that enables:
- Scanning QR Codes using the device camera.
- Real-time scan result handling.
- Customizable UI for masking and displaying QR scan regions.

This module is compatible with **iOS 16 and above** and designed for seamless integration via **Swift Package Manager (SPM)**.

---

## **Features**

- ✅ **QR Code Scanning**: Efficient and accurate QR code scanning using the camera.
- ✅ **Customizable UI**: Supports custom overlays for QR scan regions.
- ✅ **Easy Integration**: Minimal setup required with straightforward APIs.

---

## **Requirements**

| Requirement     | Minimum Version         |
|------------------|-------------------------|
| **iOS**         | 16.0                    |
| **Swift**       | 5.7                     |
| **Xcode**       | 14.0                    |

---

## **Installation**

### **Swift Package Manager (SPM)**

1. Open your project in **Xcode**.
2. Navigate to **File > Add Packages...**.
3. Enter the repository URL:  
   `https://github.com/netcanis/feat_qr.git`
4. Select the version and integrate the package into your project.

---

## **Usage**

### **1. Start QR Code Scanning**

To start scanning for QR codes:

```swift
import feat_qr

HiQrScanner.shared.start { result in
    print("QR Code Scanned: \(result.data)")
    HiQrScanner.shared.stop()
}
```

### **2. Stop QR Code Scanning**
Stop scanning when it’s no longer needed:

```swift
HiQrScanner.shared.stop()
```

### **3. Custom UI for QR Scanning**
You can provide your own preview view and scan region overlay:

```swift
import feat_qr

let qrScanner = HiQrScanner()
let customPreviewView = UIView() // Replace with your preview view
let scanBox = CGRect(x: 50, y: 100, width: 200, height: 200)

qrScanner.start(previewView: customPreviewView, roi: scanBox) { result in
    print("QR Code Scanned: \(result.data)")
    qrScanner.stop()
}
```

---

## **HiQrResult**

The scan results are provided in the HiQrResult class. Here are its properties:

| Property          | Type           | Description               |
|-------------------|----------------|---------------------------|
| data              | String         | The scanned QR code data. |
| error             | String         | Error message, if any.    |

---

## **Permissions**

Add the following key to your Info.plist file to request camera permission:

```
<key>NSCameraUsageDescription</key>
<string>We use the camera to scan QR codes.</string>
```

---

## **Example UI**

To display a SwiftUI view for managing QR code scans:

```swift
import SwiftUI
import feat_qr

public struct HiQrCodeListView: View {
    @State private var codes: [(date: Date, code: String)] = []

    public var body: some View {
        VStack {
            List(codes, id: \.code) { result in
                VStack(alignment: .leading) {
                    Text("Scanned Date: \(result.date.formatted())")
                    Text("QR Code: \(result.code)")
                }
            }
            .navigationTitle("QR Code Scans")
            .onAppear(perform: startQrScan)
            .onDisappear { HiQrScanner.shared.stop() }
        }
    }

    private func startQrScan() {
        HiQrScanner.shared.start { result in
            let qrCode = result.data
            if let index = codes.firstIndex(where: { $0.code == qrCode }) {
                codes[index] = (date: Date(), code: qrCode)
            } else {
                codes.append((date: Date(), code: qrCode))
            }
        }
    }
}

#Preview {
    HiQrCodeListView()
}
```

---

## **License**

feat_qr is available under the MIT License. See the LICENSE file for details.

---

## **Contributing**

Contributions are welcome! To contribute:

1. Fork this repository.
2. Create a feature branch:
```
git checkout -b feature/your-feature
```
3. Commit your changes:
```
git commit -m "Add feature: description"
```
4. Push to the branch:
```
git push origin feature/your-feature
```
5. Submit a Pull Request.

---

## **Author**

### **netcanis**
GitHub: https://github.com/netcanis

---
