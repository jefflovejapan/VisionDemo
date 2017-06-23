//
//  PreviewView.swift
//  EduardosEverywhere
//
//  Created by Jeffrey Blagdon on 6/23/17.
//  Copyright © 2017 Jeff. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class RectsView: UIView {
    static let layerCount = 20
    let shapeLayers: [CAShapeLayer] = [0 ..< RectsView.layerCount].map { _ in CAShapeLayer() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureLayers()
    }

    private func configureLayers() {
        backgroundColor = .clear
        for layer in shapeLayers {
            self.layer.addSublayer(layer)
            layer.strokeColor = UIColor.yellow.cgColor
            layer.fillColor = UIColor.yellow.withAlphaComponent(0.2).cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for layer in shapeLayers {
            layer.frame = self.layer.bounds
        }
    }

    var rects: [VNRectangleObservation] = [] {
        didSet {
//            CATransaction.begin()
//            for layer in shapeLayers {
//                layer.path = nil
//            }
//            for (rect, layer) in zip(rects, shapeLayers) {
//                let path = UIBezierPath()
//                path.move(to: rect.topLeft)
//                path.addLine(to: rect.topRight)
//                path.addLine(to: rect.bottomRight)
//                path.addLine(to: rect.bottomLeft)
//                path.addLine(to: rect.topLeft)
//                path.close()
//                path.fill()
//                path.stroke()
//                layer.path = path.cgPath
//            }
//            CATransaction.commit()
        }
    }
}

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }

        return layer
    }

    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    // MARK: UIView

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
