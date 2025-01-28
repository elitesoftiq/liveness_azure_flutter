import Foundation
import SwiftUI
import AVFoundation
import AzureAIVisionFace

struct CameraView: View {
    @Binding var backgroundColor: Color?
    @Binding var feedbackMessage: String
    @Binding var isCameraPreviewVisible: Bool
    @State private var progress: CGFloat = 0.0
    static let circleDiameterRatio: CGFloat = 0.8
    let onViewDidLoad: (VisionSource) -> Void

    @State private var isAnimating = false

    @State private var isLoading: Bool = true

    @State private var timer: Timer?

    private func updateProgress() {

        guard !isAnimating else { return }

        withAnimation(.easeInOut(duration: 1.5)) {
            isAnimating = true
            progress = feedbackMessage == "Hold Still." ? 1.0 : 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAnimating = false
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {

                Color.black
                    .ignoresSafeArea()

                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else {

                    CameraPreviewView(isCameraPreviewVisible: $isCameraPreviewVisible, onViewDidLoad: onViewDidLoad)
                        .frame(width: geometry.size.width * CameraView.circleDiameterRatio,
                               height: geometry.size.width * CameraView.circleDiameterRatio)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: geometry.size.width * CameraView.circleDiameterRatio,
                               height: geometry.size.width * CameraView.circleDiameterRatio)
                        .animation(.easeInOut(duration: 1.5), value: progress)

                    VStack {
                        Text(feedbackMessage)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .medium))
                            .padding(.top, 80)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
            }
            .onChange(of: feedbackMessage) { newValue in
                if newValue == "Hold Still." {
                    updateProgress()

                    timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                        updateProgress()
                    }
                } else {
                    timer?.invalidate()
                    timer = nil
                    withAnimation {
                        progress = 0.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isLoading = false
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct LoadingView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5

    var body: some View {
        VStack {

            Image(systemName: "camera.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                }

            Text("Loading Camera...")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.top, 20)
        }
    }
}
