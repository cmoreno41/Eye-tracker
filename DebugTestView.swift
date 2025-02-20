// DebugTestView.swift

import SwiftUI
import ARKit

struct DebugTestView: View {
    @StateObject private var viewModel = EyeTrackingViewModel()
    @State private var statusMessage = "Initializing..."
    @State private var isGestureActive = false
    @State private var showDebugOverlay = true
    @State private var successfulGestures = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // AR Face tracking preview
                ARViewContainer(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                // Eye direction indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .position(
                        x: viewModel.eyePosition.x * geometry.size.width,
                        y: viewModel.eyePosition.y * geometry.size.height
                    )
                    .opacity(0.7)
                
                // Gesture detection zone
                Path { path in
                    path.addRect(CGRect(
                        x: geometry.size.width * 0.95,
                        y: 0,
                        width: geometry.size.width * 0.05,
                        height: geometry.size.height
                    ))
                }
                .fill(Color.yellow.opacity(0.2))
                
                // Debug overlay
                if showDebugOverlay {
                    VStack {
                        // Status panel
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AR Face Tracking Debug")
                                .font(.headline)
                            
                            Text("Status: \(statusMessage)")
                                .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                            
                            Text("Tracking: \(viewModel.isTracking ? "Active" : "Inactive")")
                            
                            Text("Eye Direction: (x: \(String(format: "%.2f", viewModel.eyePosition.x)), y: \(String(format: "%.2f", viewModel.eyePosition.y)))")
                            
                            Text("In Gesture Zone: \(viewModel.eyePosition.x > 0.95 ? "Yes" : "No")")
                                .foregroundColor(viewModel.eyePosition.x > 0.95 ? .green : .gray)
                            
                            Text("Successful Gestures: \(successfulGestures)")
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                        
                        // Control buttons
                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.toggleTracking()
                                updateStatus("Tracking \(viewModel.isTracking ? "Started" : "Stopped")")
                            }) {
                                Text(viewModel.isTracking ? "Stop Tracking" : "Start Tracking")
                                    .padding()
                                    .background(viewModel.isTracking ? Color.red : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                successfulGestures = 0
                                updateStatus("Counters Reset")
                            }) {
                                Text("Reset Counters")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            if !viewModel.isTracking {
                viewModel.toggleTracking()
            }
        }
    }
    
    private func updateStatus(_ message: String) {
        statusMessage = message
    }
}

struct ARViewContainer: UIViewRepresentable {
    let viewModel: EyeTrackingViewModel
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: CGRect.zero)
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
    }
}
