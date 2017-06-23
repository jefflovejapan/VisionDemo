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

    private let session = AVCaptureSession()

    private var isSessionRunning = false

    private let sessionQueue = DispatchQueue(label: "session queue", qos: DispatchQoS.userInteractive)
    private let notificationQueue = OperationQueue()

    private var requests: [VNRequest] = []

    func setupVision() {
        let rectRequest = VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
        rectRequest.minimumSize = 0.1
        rectRequest.maximumObservations = 20

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
        print("results: \(results)")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("couldn't get buffer")
            return
        }

        let requestOptions: [VNImageOption: Any]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        } else {
            requestOptions = [:]
        }

        let exifOrientation = self.exifOrientationFromDeviceOrientation()

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print("error performing requests: \(error)")
        }
    }

    private func exifOrientationFromDeviceOrientation() -> Int32 {
        switch UIDevice.current.orientation {
        case .portrait:
            return 1
        case .portraitUpsideDown:
            return 3
        case .landscapeLeft:
            return 6
        case .landscapeRight:
            return 8
        default:
            return 0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        previewView?.session = session
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

