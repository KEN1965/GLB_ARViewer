import SwiftUI
import ReplayKit
import AudioToolbox

struct SnapshotItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ARGLBContainerView: View {
    let glbURL: URL
    var onBack: (() -> Void)?
    var onClose: (() -> Void)?

    @State private var arViewInstanceID = UUID()
    @State private var showARIssueBanner = false

    @State private var snapshotItem: SnapshotItem?

    @State private var isVideoMode = false
    @State private var isRecording = false
    @State private var isCountingDown = false
    @State private var countdownValue = 3

    @State private var previewDelegate: ARRecordingPreviewDelegate?

    private var showControls: Bool {
        !isRecording && !isCountingDown
    }

    var body: some View {
        ZStack {
            ARGLBView(glbURL: glbURL)
                .id(arViewInstanceID)
                .ignoresSafeArea()

            if let item = snapshotItem {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                SnapshotPreviewView(
                    image: item.image,
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            snapshotItem = nil
                        }
                    },
                    onSaved: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            snapshotItem = nil
                        }
                        onClose?()
                    }
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }

            if showControls {
                VStack {
                    HStack {
                        Button {
                            if isRecording {
                                stopRecording()
                            }
                            onBack?()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }

                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 12)

                    Spacer()

                    HStack {
                        Button {
                            if !isRecording {
                                isVideoMode.toggle()
                            }
                        } label: {
                            Image(systemName: isVideoMode ? "video.fill" : "camera.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button {
                            if isVideoMode {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    startCountdownThenRecord()
                                }
                            } else {
                                NotificationCenter.default.post(name: .takeSnapshot, object: nil)
                            }
                        } label: {
                            if isVideoMode {
                                Circle()
                                    .fill(isRecording ? Color.red : Color.white)
                                    .frame(width: 70, height: 70)
                            } else {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                                    .background(Circle().fill(Color.white.opacity(0.2)))
                            }
                        }

                        Spacer()

                        Button {
                            NotificationCenter.default.post(name: .toggleAutoRotate, object: nil)
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }

            if isCountingDown {
                VStack(spacing: 12) {
                    Text("\(countdownValue)")
                        .font(.system(size: 84, weight: .bold))
                        .foregroundColor(.white)

                    Text("録画開始まで")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("画面をタップしたら終了")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                }
            }

            if showARIssueBanner && showControls {
                VStack {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AR Camera Issue")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                            Text("カメラ入力が停止しました。再開をお試しください。")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer()

                        Button("再開") {
                            arViewInstanceID = UUID()
                            showARIssueBanner = false
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.cyan)
                        .clipShape(Capsule())
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 18)
                    .padding(.top, 86)

                    Spacer()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didTakeSnapshot)) { notification in
            if let image = notification.object as? UIImage {
                withAnimation(.easeInOut(duration: 0.2)) {
                    snapshotItem = SnapshotItem(image: image)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .arSensorFailure)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showARIssueBanner = true
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                if isRecording {
                    stopRecording()
                }
            }
        )
    }

    private func startCountdownThenRecord() {
        guard !isRecording, !isCountingDown else { return }

        countdownValue = 3
        isCountingDown = true

        func tick() {
            if countdownValue > 1 {
                AudioServicesPlaySystemSound(1104)
                countdownValue -= 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    tick()
                }
            } else {
                isCountingDown = false
                startRecording()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            tick()
        }
    }

    private func startRecording() {
        let recorder = RPScreenRecorder.shared()
        recorder.isMicrophoneEnabled = false

        recorder.startRecording { error in
            DispatchQueue.main.async {
                if let error {
                    print("録画開始エラー:", error)
                    isRecording = false
                    return
                }
                isRecording = true
            }
        }
    }

    private func stopRecording() {
        guard isRecording else {
            return
        }

        let recorder = RPScreenRecorder.shared()

        recorder.stopRecording { previewVC, error in
            DispatchQueue.main.async {
                isRecording = false

                if let error {
                    print("録画停止エラー:", error)
                    return
                }

                guard let previewVC else { return }

                let delegate = ARRecordingPreviewDelegate()
                delegate.onFinish = {
                    onClose?()
                }
                previewDelegate = delegate
                previewVC.previewControllerDelegate = delegate

                UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                    .first?
                    .rootViewController?
                    .present(previewVC, animated: true)
            }
        }
    }
}

final class ARRecordingPreviewDelegate: NSObject, RPPreviewViewControllerDelegate {
    var onFinish: (() -> Void)?

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true)
        onFinish?()
    }
}
