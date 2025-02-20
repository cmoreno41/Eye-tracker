// CameraTestView.swift

import SwiftUI
import AVFoundation

struct CameraTestView: View {
    @StateObject private var viewModel = CameraTestViewModel()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: viewModel.captureSession)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay for orientation markers
            VStack {
                Text("TOP")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                
                Spacer()
                
                HStack {
                    Text("LEFT")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Text("RIGHT")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
                
                Spacer()
                
                Text("BOTTOM")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.yellow)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
            .padding()
            
            // Camera status indicator
            VStack {
                Spacer()
                if viewModel.isCameraRunning {
                    Text("Camera Active")
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                } else {
                    Text("Camera Inactive")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
            }
            .padding(.bottom)
        }
        .onAppear {
            viewModel.checkCameraPermission()
        }
    }
}

class CameraTestViewModel: ObservableObject {
    @Published var isCameraRunning = false
    let captureSession = AVCaptureSession()
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }
    
    private func setupCamera() {
        do {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .video,
                                                     position: .front) else { return }
            
            let input = try AVCaptureDeviceInput(device: device)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if let videoOutput = captureSession.outputs.first as? AVCaptureVideoDataOutput,
               let connection = videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(0) {
                        connection.videoRotationAngle = 0
                    }
                } else {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
                connection.isVideoMirrored = true
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession.startRunning()
                DispatchQueue.main.async {
                    self?.isCameraRunning = true
                }
            }
            
        } catch {
            print("Camera setup failed: \(error.localizedDescription)")
        }
    }
}
