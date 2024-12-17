//
//  HiMaskView.swift
//  feat_qr
//
//  Created by netcanis on 11/4/24.
//

import UIKit

/// A custom view that displays a dimmed overlay with a transparent scan box (Region of Interest) and corner lines.
public class HiQrRoiMaskView: UIView {

    /// The rectangle representing the Region of Interest (ROI).
    public var scanBox: CGRect = .zero {
        didSet {
            setNeedsDisplay() // Redraw when scanBox changes
        }
    }

    /// The dimming color for the overlay (default is semi-transparent black).
    public var dimColor: UIColor = UIColor.black.withAlphaComponent(0.5)

    /// The thickness of the corner lines.
    public var lineThickness: CGFloat = 4.0

    /// The color of the corner lines (default is red).
    public var cornerLineColor: UIColor = .red

    /// Draws the overlay and corner lines.
    public override func draw(_ rect: CGRect) {
        guard !scanBox.isEmpty else { return }

        // Retrieve the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()

        // Fill the entire view with the dimming color
        dimColor.setFill()
        context.fill(rect)

        // Clear the scanBox area to make it transparent
        context.setBlendMode(.clear)
        context.fill(scanBox)
        context.setBlendMode(.normal)

        // Set the stroke color for corner lines
        cornerLineColor.setStroke()
        let cornerLength: CGFloat = 40.0 // Length of the corner lines

        // Draw the corner lines for each corner of the scanBox
        // Top-left corner
        drawCorner(context: context, startPoint: scanBox.origin, horizontalLength: cornerLength, verticalLength: cornerLength, thickness: lineThickness)

        // Top-right corner
        drawCorner(context: context, startPoint: CGPoint(x: scanBox.maxX, y: scanBox.minY), horizontalLength: -cornerLength, verticalLength: cornerLength, thickness: lineThickness)

        // Bottom-left corner
        drawCorner(context: context, startPoint: CGPoint(x: scanBox.minX, y: scanBox.maxY), horizontalLength: cornerLength, verticalLength: -cornerLength, thickness: lineThickness)

        // Bottom-right corner
        drawCorner(context: context, startPoint: CGPoint(x: scanBox.maxX, y: scanBox.maxY), horizontalLength: -cornerLength, verticalLength: -cornerLength, thickness: lineThickness)

        context.restoreGState()
    }

    /// Draws corner lines at the specified start point.
    /// - Parameters:
    ///   - context: The current graphics context.
    ///   - startPoint: The starting point of the corner.
    ///   - horizontalLength: The length of the horizontal corner line.
    ///   - verticalLength: The length of the vertical corner line.
    ///   - thickness: The thickness of the lines.
    private func drawCorner(context: CGContext, startPoint: CGPoint, horizontalLength: CGFloat, verticalLength: CGFloat, thickness: CGFloat) {
        context.setLineWidth(thickness)
        context.beginPath()

        // Draw horizontal line
        context.move(to: startPoint)
        context.addLine(to: CGPoint(x: startPoint.x + horizontalLength, y: startPoint.y))
        context.strokePath()

        // Draw vertical line
        context.move(to: startPoint)
        context.addLine(to: CGPoint(x: startPoint.x, y: startPoint.y + verticalLength))
        context.strokePath()
    }
}
