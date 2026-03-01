import SwiftUI
import ARKit

struct ARCameraDiagnosticContainerView: View {
    var onBack: (() -> Void)?

    @State private var instanceID = UUID()
    @State private var trackingText = "Tracking: starting..."
    @State private var errorText = "Error: none"

    var body: some View {
        ZStack {
            ARCameraDiagnosticView(
                onTrackingChange: { text in
                    trackingText = "Tracking: \(text)"
                },
                onError: { text in
                    errorText = "Error: \(text)"
                }
            )
            .id(instanceID)
            .ignoresSafeArea()

            VStack(spacing: 10) {
                HStack {
                    Button {
                        onBack?()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button("再起動") {
                        instanceID = UUID()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cyan)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("AR Camera Diagnostic")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(trackingText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(errorText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 18)

                Spacer()
            }
        }
    }
}

struct ARCameraDiagnosticView: UIViewRepresentable {
    var onTrackingChange: (String) -> Void
    var onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTrackingChange: onTrackingChange, onError: onError)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.autoenablesDefaultLighting = true
        view.delegate = context.coordinator
        view.session.delegate = context.coordinator

        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .none
        view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
        uiView.delegate = nil
        uiView.session.delegate = nil
    }

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        let onTrackingChange: (String) -> Void
        let onError: (String) -> Void

        init(onTrackingChange: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onTrackingChange = onTrackingChange
            self.onError = onError
        }

        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            switch camera.trackingState {
            case .normal:
                onTrackingChange("normal")
            case .notAvailable:
                onTrackingChange("notAvailable")
            case .limited(let reason):
                onTrackingChange("limited(\(reason))")
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            onError(error.localizedDescription)
            print("AR Diagnostic failed:", error.localizedDescription)
        }
    }
}
