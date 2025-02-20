// EyeTrackingManager.swift

import UIKit
import AVFoundation
import Vision

class EyeTrackingManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var gesturePoints: [CGPoint] = []
    private var gestureStartTime: Date?
    private var isTrackingGesture = false
    private let gestureTimeout: TimeInterval = 1.0
    
    // Callbacks
    var onEyePositionUpdate: ((CGPoint) -> Void)?
    var onGestureStateChange: ((Bool) -> Void)?
    var onGestureDetected: (() -> Void)?
    
    // Threshold values
    private let rightEdgeThreshold: CGFloat = 0.95
    private let verticalThreshold: CGFloat = 0.2
    
    override init() {
        super.init()
        print("EyeTrackingManager initialized")
    }
    
    func setupCamera() throws {
        print("Setting up camera...")
        let session = AVCaptureSession()
        session.sessionPreset = .high
        self.captureSession = session
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .front) else {
            print("Failed to get front camera")
            throw NSError(domain: "EyeTracking",
                         code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Front camera not available"])
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
            print("Added camera input")
        }
        
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            print("Added video output")
        }
        
        // Configure video orientation
        if let connection = videoDataOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(0) {
                    connection.videoRotationAngle = 0
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        print("Camera setup complete")
    }
    
    func startTracking() {
        print("Starting tracking...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            print("Capture session started")
        }
    }
    
    func stopTracking() {
        print("Stopping tracking...")
        captureSession?.stopRunning()
    }
    
    // MARK: - Camera Delegate Methods
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer")
            return
        }
        
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            if let error = error {
                print("Face detection error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation],
                  let face = observations.first else {
                print("No face detected")
                return
            }
            
            guard let landmarks = face.landmarks,
                  let leftEye = landmarks.leftEye?.normalizedPoints,
                  let rightEye = landmarks.rightEye?.normalizedPoints else {
                print("No eye landmarks detected")
                return
            }
            
            // Calculate eye positions
            let leftEyeCenter = self?.calculateEyeCenter(from: leftEye)
            let rightEyeCenter = self?.calculateEyeCenter(from: rightEye)
            
            if let left = leftEyeCenter, let right = rightEyeCenter {
                let averagePosition = CGPoint(
                    x: (left.x + right.x) / 2,
                    y: (left.y + right.y) / 2
                )
                
                DispatchQueue.main.async {
                    self?.onEyePositionUpdate?(averagePosition)
                    self?.detectEyeMovement(from: averagePosition)
                }
            }
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer,
                                                      orientation: .rightMirrored,
                                                      options: [:])
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print("Failed to perform face detection: \(error)")
        }
    }
    
    private func calculateEyeCenter(from points: [CGPoint]) -> CGPoint {
        let xSum = points.reduce(0) { $0 + $1.x }
        let ySum = points.reduce(0) { $0 + $1.y }
        let count = CGFloat(points.count)
        return CGPoint(x: xSum / count, y: ySum / count)
    }
    
    private func detectEyeMovement(from position: CGPoint) {
        if position.x > rightEdgeThreshold && !isTrackingGesture {
            startGestureTracking(at: position)
        }
        
        if isTrackingGesture {
            gesturePoints.append(position)
            checkGestureCompletion()
        }
    }
    
    private func startGestureTracking(at position: CGPoint) {
        isTrackingGesture = true
        gesturePoints = [position]
        gestureStartTime = Date()
        onGestureStateChange?(true)
        print("Started gesture tracking")
    }
    
    private func checkGestureCompletion() {
        guard let startTime = gestureStartTime else { return }
        
        if Date().timeIntervalSince(startTime) > gestureTimeout {
            resetGestureTracking()
            return
        }
        
        guard gesturePoints.count >= 5 else { return }
        
        let startPoint = gesturePoints.first!
        let endPoint = gesturePoints.last!
        let verticalMovement = startPoint.y - endPoint.y
        
        if verticalMovement > verticalThreshold &&
            endPoint.x > rightEdgeThreshold {
            print("Gesture detected!")
            DispatchQueue.main.async { [weak self] in
                self?.onGestureDetected?()
                self?.resetGestureTracking()
            }
        }
    }
    
    private func resetGestureTracking() {
        isTrackingGesture = false
        gesturePoints.removeAll()
        gestureStartTime = nil
        onGestureStateChange?(false)
        print("Reset gesture tracking")
    }
    
    func startCalibration() {
        print("Starting calibration")
        resetGestureTracking()
    }
}
