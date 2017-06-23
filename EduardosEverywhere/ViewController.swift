//
//  ViewController.swift
//  EduardosEverywhere
//
//  Created by Jeffrey Blagdon on 6/23/17.
//  Copyright © 2017 Jeff. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import CoreMedia

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var previewView: PreviewView?
    @IBOutlet weak var rectsView: RectsView?
    @IBOutlet weak var rectsViewWidth: NSLayoutConstraint?

    private let session = AVCaptureSession()

    private var isSessionRunning = false
    private var imageSize: CGSize = .zero {
        didSet {
            guard imageSize != oldValue else { return }
            let imgSize = imageSize
            DispatchQueue.main.async {
                let longDimension = max(imgSize.width, imgSize.height)
                let shortDimension = min(imgSize.width, imgSize.height)
                let pointWidth = self.view.bounds.size.height * (shortDimension / longDimension)
                self.rectsViewWidth?.constant = pointWidth
            }
        }
    }

    private let sessionQueue = DispatchQueue(label: "session queue", qos: DispatchQoS.userInteractive)
    private let notificationQueue = OperationQueue()

    private var requests: [VNRequest] = []

    func setupVision() {
        let rectRequest = VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
        rectRequest.minimumSize = 0.1
        rectRequest.maximumObservations = RectsView.layerCount

        self.requests.append(rectRequest)
    }

    private func handleRectangles(request: VNRequest, error: Error?) {
        if let error = error {
            print("got an error: \(error)")
            return
        }

        guard let results = request.results as? [VNObservation] else {
            print("can't use results: \(String(describing: request.results))")
            return
        }

        DispatchQueue.main.async {
            self.drawVisionRequestResults(results)
        }
    }

    private func drawVisionRequestResults(_ results: [VNObservation]) {
        guard let rectsView = rectsView else { return }
        let rectObs = results.flatMap { $0 as? VNRectangleObservation }
        let rects = rectObs.map { rect in rect.scale(inRect: rectsView.bounds) }
        rectsView.rects = rects
    }



    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("couldn't get buffer")
            return
        }

        self.imageSize = CVImageBufferGetDisplaySize(pixelBuffer)

        let requestOptions: [VNImageOption: Any]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        } else {
            requestOptions = [:]
        }

        let orientation = UIDevice.current.orientation
        print("Our orientation is \(orientation.name)")
        let exifOrientation = self.exifOrientation(from: orientation)

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print("error performing requests: \(error)")
        }
    }

    private func exifOrientation(from deviceOrientation: UIDeviceOrientation) -> Int32 {
        return 6
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        previewView?.session = session
        rectsView?.backgroundColor = UIColor.cyan.withAlphaComponent(0.2)
        setupVision()

        guard let device = AVCaptureDevice.default(for: .video) else {
            print("couldnt' get the video device")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
        } catch {
            print("Error adding device: \(error)")
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil, queue: notificationQueue) { (note) in
            print("Got an AVSession runtime error: \(dump(note))")
        }
        session.startRunning()
    }
}

extension CGPoint {
    func scaleWithInverseOrigin(inRect rect: CGRect) -> CGPoint {
        var newPoint = CGPoint.zero
        newPoint.x = rect.minX + (rect.width * self.x)
        newPoint.y = rect.maxY - (rect.height * self.y)
        return newPoint
    }
}

struct Quadrilateral {
    var point0: CGPoint
    var point1: CGPoint
    var point2: CGPoint
    var point3: CGPoint
}

extension Quadrilateral {
    init() {
        self.point0 = .zero
        self.point1 = .zero
        self.point2 = .zero
        self.point3 = .zero
    }
}

extension VNRectangleObservation {
    func scale(inRect rect: CGRect) -> Quadrilateral {
        print("scaling an obs. topLeft: \(self.topLeft), topRight: \(self.topRight), btmRight: \(self.bottomRight), btmLeft: \(self.bottomLeft)")
        var quad = Quadrilateral()
        quad.point0 = self.topLeft.scaleWithInverseOrigin(inRect: rect)
        quad.point1 = self.topRight.scaleWithInverseOrigin(inRect: rect)
        quad.point2 = self.bottomRight.scaleWithInverseOrigin(inRect: rect)
        quad.point3 = self.bottomLeft.scaleWithInverseOrigin(inRect: rect)
        print("calculated quad: \(quad)")
        return quad
    }
}

extension UIDeviceOrientation {
    var name: String {
        switch self {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        default:
            return "weird"
        }
    }
}
