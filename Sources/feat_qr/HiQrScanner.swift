//
//  HiQrScanner.swift
//  feat_qr
//
//  Created by netcanis on 11/1/24.
//

import AVFoundation
import UIKit

// MARK: - Class Overview
/// A class responsible for managing QR code scanning operations using the camera.
public class HiQrScanner: NSObject, @unchecked Sendable {

    // MARK: - Singleton Instance
    /// A shared singleton instance for global access.
    public static let shared = HiQrScanner()

    // MARK: - Private Properties
    /// Scanning state flag
    private var isScanning: Bool = false
    /// Callback to return the scanned QR result
    private var scanCallback: ((HiQrResult) -> Void)?

    /// References for UI components
    private var parentView: UIView?
    private var previewView: UIView?
    private var maskView: HiQrRoiMaskView?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var torchButton: UIButton?
    private var closeButton: UIButton?

    // MARK: - Public Methods

    /// Starts the QR code scanning session with a callback.
    /// - Parameter callback: A closure that provides the scanned result.
    public func start(withCallback callback: @escaping (HiQrResult) -> Void) {
        guard !isScanning else {
            print("QR scanning is already in progress.")
            return
        }

        self.scanCallback = callback

        if hasRequiredPermissions() {
            setupAndStartScanning()
        } else {
            requestCameraPermissionAndStartScanning()
        }
    }

    /// Stops the QR scanning session.
    @MainActor
    public func stop() {
        guard isScanning else { return }
        isScanning = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.resetUI()
        }
    }

    /// Checks if camera permissions have been granted.
    /// - Returns: Boolean indicating if the camera is accessible.
    public func hasRequiredPermissions() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    /// Toggles the device's torch (flashlight) on or off.
    /// - Parameter isOn: Boolean flag for torch state.
    public func toggleTorch(isOn: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure the torch: \(error)")
        }
    }

    // MARK: - UI Setup Methods

    /// Sets up the camera preview UI.
    @MainActor
    private func setupPreviewUI() {
        parentView = UIViewController.hiTopMostViewController()?.view
        guard let parentView = parentView else {
            scanCallback?(HiQrResult(qrData: "", error: "Parent view is not available."))
            stop()
            return
        }

        // Set up the preview view for displaying the camera feed.
        previewView = UIView(frame: parentView.bounds)
        previewView?.backgroundColor = .black
        parentView.addSubview(previewView!)

        previewLayer?.frame = previewView?.layer.bounds ?? UIScreen.main.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        previewView?.layer.addSublayer(previewLayer!)
    }

    /// Adds the mask view and torch/close buttons to the preview UI.
    @MainActor
    private func setupMaskAndButtons() {
        let sideMargin: CGFloat = 40
        let boxWidth = previewView!.bounds.width - (sideMargin * 2)
        let scanBox = CGRect(x: sideMargin, y: (previewView!.bounds.height - boxWidth) / 2, width: boxWidth, height: boxWidth)

        // Mask view highlights the scan area
        maskView = HiQrRoiMaskView(frame: previewView!.bounds)
        maskView?.backgroundColor = .clear
        maskView?.scanBox = scanBox
        previewView?.addSubview(maskView!)

        // Torch button to toggle flashlight
        let bundle = getFeatQrBundle()
        torchButton = UIButton(type: .custom)
        torchButton?.setImage(UIImage(named: "flashOff", in: bundle, compatibleWith: nil), for: .normal)
        torchButton?.frame = CGRect(x: 20, y: 50, width: 30, height: 30)
        torchButton?.addTarget(self, action: #selector(self.onTorch), for: .touchUpInside)
        previewView?.addSubview(torchButton!)

        // Close button to stop scanning
        closeButton = UIButton(type: .custom)
        closeButton?.setImage(UIImage(named: "closeWhite", in: bundle, compatibleWith: nil), for: .normal)
        closeButton?.frame = CGRect(x: parentView!.bounds.width - 50, y: 50, width: 30, height: 30)
        closeButton?.addTarget(self, action: #selector(self.onClose), for: .touchUpInside)
        previewView?.addSubview(closeButton!)
    }

    /// Resets the UI components and stops the session.
    private func resetUI() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.captureSession = nil
            self.previewLayer = nil
            self.parentView = nil
            self.previewView?.removeFromSuperview()
            self.previewView = nil
            self.torchButton = nil
            self.closeButton = nil
            self.maskView = nil

            print("QR scanning has been stopped.")
        }
    }

    // MARK: - Initialization Methods

    /// Initializes the capture session and sets up video input and output.
    @MainActor
    private func initialize() {
        guard !isScanning else {
            print("QR scanning is already in progress.")
            return
        }

        captureSession = AVCaptureSession()
        guard let captureSession = captureSession,
              let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            scanCallback?(HiQrResult(qrData: "", error: "Failed to access the camera."))
            stop()
            return
        }

        // Add input to capture session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            captureSession.sessionPreset = .high
            setFocusAtCenter(videoDevice: videoCaptureDevice)
        }

        // Add metadata output for QR scanning
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.connection(with: .video)?.videoOrientation = .portrait
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "com.example.QRScanner.metadataProcessing"))
            metadataOutput.metadataObjectTypes = [.qr]
        }

        // Configure the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    }

    private func setupAndStartScanning() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.initialize()
            self.setupPreviewUI()
            self.setupMaskAndButtons()
            self.beginCaptureSession()
        }
    }

    private func requestCameraPermissionAndStartScanning() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if granted {
                    self.setupAndStartScanning()
                } else {
                    print("Camera access is required.")
                }
            }
        }
    }

    /// Begins the capture session asynchronously.
    private func beginCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            self?.isScanning = true
        }
    }

    /// Sets the focus point of the camera at the center.
    private func setFocusAtCenter(videoDevice: AVCaptureDevice) {
        guard videoDevice.isFocusPointOfInterestSupported else { return }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            videoDevice.focusMode = .continuousAutoFocus
            videoDevice.unlockForConfiguration()
        } catch {
            print("Failed to set focus: \(error)")
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension HiQrScanner: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let qrString = metadataObject.stringValue else { return }

        Task { @MainActor [weak self] in
            guard let self = self, self.isScanning else { return }
            self.scanCallback?(HiQrResult(qrData: qrString))
        }
    }
}

// MARK: - Events
extension HiQrScanner {
    @MainActor
    @objc private func onTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        let isTorchOn = device.torchMode == .on
        toggleTorch(isOn: !isTorchOn)

        let bundle = getFeatQrBundle()
        let torchImageName = isTorchOn ? "flashOff" : "flashOn"
        torchButton?.setImage(UIImage(named: torchImageName, in: bundle, compatibleWith: nil), for: .normal)
    }

    @MainActor
    @objc private func onClose() {
        stop()
    }
}

// MARK: - Custom UI Integration
extension HiQrScanner {
    /// Starts the QR scanning session with a custom UI preview and scan region of interest (ROI).
    /// - Parameters:
    ///   - previewView: A view that displays the camera preview.
    ///   - roi: The rectangular region for scanning within the preview.
    ///   - callback: A closure providing the scanned QR result.
    public func start(previewView: UIView, roi: CGRect, withCallback callback: @escaping (HiQrResult) -> Void) {
        // Ensure scanning is not already in progress
        guard !isScanning else {
            print("QR scanning is already in progress.")
            return
        }

        self.scanCallback = callback

        // Start scanning if permissions are available
        if hasRequiredPermissions() {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.previewView = previewView
                self.initialize()
                self.setupCustomPreviewUI(previewView, roi)
                self.beginCaptureSession()
            }
        } else {
            // Request camera access if permissions are not granted
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if granted {
                        self.previewView = previewView
                        self.initialize()
                        self.setupCustomPreviewUI(previewView, roi)
                        self.beginCaptureSession()
                    } else {
                        print("Camera access is required.")
                    }
                }
            }
        }
    }

    /// Configures a custom preview layer and mask for the given region of interest (ROI).
    /// - Parameters:
    ///   - previewView: The parent view for displaying the preview.
    ///   - roi: The rectangular scan area within the preview view.
    @MainActor
    public func setupCustomPreviewUI(_ previewView: UIView?, _ roi: CGRect?) {
        previewView?.layoutIfNeeded()

        // Configure the preview layer to match the view's bounds
        previewLayer?.frame = previewView?.layer.bounds ?? UIScreen.main.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        previewView?.layer.addSublayer(previewLayer!)

        // Add a mask view to highlight the scanning region
        maskView = HiQrRoiMaskView(frame: previewView!.bounds)
        maskView?.backgroundColor = .clear
        maskView?.scanBox = roi!
        previewView?.addSubview(maskView!)
    }
}

// MARK: - Top ViewController Finder
extension UIViewController {
    /// Retrieves the top-most view controller in the app's hierarchy.
    /// - Returns: The top-most `UIViewController` instance.
    static func hiTopMostViewController() -> UIViewController? {
        guard let keyWindow = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let rootViewController = keyWindow.rootViewController else {
            return nil
        }
        return hiGetTopViewController(from: rootViewController)
    }

    /// Recursively traverses the view controller hierarchy to find the top-most view controller.
    /// - Parameter viewController: The starting view controller.
    /// - Returns: The top-most `UIViewController`.
    private static func hiGetTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return hiGetTopViewController(from: presentedViewController)
        }
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return hiGetTopViewController(from: visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return hiGetTopViewController(from: selectedViewController)
        }
        return viewController
    }
}
