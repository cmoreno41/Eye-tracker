// CalibrationView.swift

import SwiftUI

struct CalibrationView: View {
    @Binding var isCalibrating: Bool
    @State private var dotPosition: CGPoint = CGPoint(x: 0.95, y: 0.5)
    @State private var calibrationStep = 0
    @State private var showCompletionButton = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // Calibration dot
                Circle()
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                    .position(
                        x: dotPosition.x * geometry.size.width,
                        y: dotPosition.y * geometry.size.height
                    )
                    .animation(.easeInOut(duration: 2.0), value: dotPosition)
                
                VStack {
                    // Instructions
                    Text(calibrationStep == 0 ? "Follow the dot with your eyes" : "Keep following...")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    // Done button
                    if showCompletionButton {
                        Button("Done") {
                            isCalibrating = false
                        }
                        .font(.title3)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            startCalibrationSequence()
        }
    }
    
    private func startCalibrationSequence() {
        // Start at bottom position
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Move dot up
            calibrationStep = 1
            withAnimation(.easeInOut(duration: 3.0)) {
                dotPosition = CGPoint(x: 0.95, y: 0.1)
            }
            
            // Show completion button after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                showCompletionButton = true
            }
        }
    }
}

// Preview provider
struct CalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        CalibrationView(isCalibrating: .constant(true))
    }
}
