import SwiftUI
import ARKit
import SceneKit
import AVFoundation
import AudioToolbox

#if canImport(GLTFSceneKit)
import GLTFSceneKit
#endif

#if canImport(GLTFSceneKit)

extension Notification.Name {
    static let arSensorFailure = Notification.Name("arSensorFailure")
    static let takeSnapshot = Notification.Name("takeSnapshot")
    static let didTakeSnapshot = Notification.Name("didTakeSnapshot")
    static let toggleAutoRotate = Notification.Name("toggleAutoRotate")
}

struct ARGLBView: UIViewRepresentable {
    let glbURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.delegate = context.coordinator
        view.session.delegate = context.coordinator
        view.automaticallyUpdatesLighting = true
        view.autoenablesDefaultLighting = true

        context.coordinator.sceneView = view
        context.coordinator.requestAndStartSession(on: view)
        context.coordinator.loadModelAsync(from: glbURL)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.takeSnapshot),
            name: .takeSnapshot,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.toggleAutoRotate),
            name: .toggleAutoRotate,
            object: nil
        )

        view.addGestureRecognizer(
            UIPinchGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePinch(_:))
            )
        )
        view.addGestureRecognizer(
            UIRotationGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleRotation(_:))
            )
        )
        view.addGestureRecognizer(
            UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
        )

        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        coordinator.teardown(view: uiView)
    }

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var sceneView: ARSCNView?

        private var modelNode: SCNNode?
        private var placedNode: SCNNode?
        private var isPlaced = false
        private var isTrackingNormal = false
        private var isAutoRotating = false

        func requestAndStartSession(on view: ARSCNView) {
            let start = {
                self.startSession(on: view)
            }

            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                start()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    guard granted else {
                        print("Camera permission denied")
                        return
                    }
                    DispatchQueue.main.async { start() }
                }
            default:
                print("Camera permission not granted")
            }
        }

        private func startSession(on view: ARSCNView) {
            let config = ARWorldTrackingConfiguration()
            config.environmentTexturing = .none
            view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }

        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            if case .normal = camera.trackingState {
                isTrackingNormal = true
                placeModelIfPossible()
            }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            print("ARSession failed:", error.localizedDescription)
            let nsError = error as NSError
            if nsError.domain == "com.apple.arkit.error", nsError.code == 102 {
                NotificationCenter.default.post(name: .arSensorFailure, object: nil)
            }
        }

        func sessionWasInterrupted(_ session: ARSession) {
            print("ARSession interrupted")
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            print("ARSession interruption ended")
        }

        func loadModelAsync(from url: URL) {
            print("読み込みURL:", url)
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                do {
                    let scene = try GLTFSceneSource(url: url).scene()
                    let root = SCNNode()
                    scene.rootNode.childNodes.forEach { root.addChildNode($0) }

                    root.enumerateChildNodes { node, _ in
                        if let geometry = node.geometry {
                            for material in geometry.materials {
                                material.lightingModel = .physicallyBased
                                material.isDoubleSided = true
                                if material.diffuse.contents == nil {
                                    material.diffuse.contents = UIColor.white
                                }
                            }
                        }
                    }

                    DispatchQueue.main.async {
                        self.modelNode = root
                        print("GLB読み込み成功")
                        self.placeModelIfPossible()
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("GLB load error:", error)
                    }
                }
            }
        }

        private func placeModelIfPossible() {
            guard let view = sceneView else { return }
            guard isTrackingNormal else { return }
            guard let model = modelNode else { return }
            guard !isPlaced else { return }
            guard let camera = view.pointOfView else { return }

            let transform = camera.transform
            let distance: Float = 0.45
            let verticalOffset: Float = -0.20
            let finalPosition = SCNVector3(
                transform.m41 - transform.m31 * distance,
                transform.m42 + verticalOffset,
                transform.m43 - transform.m33 * distance
            )

            let node = model.clone()
            node.eulerAngles.y -= .pi / 2
            normalizeScale(node: node)
            alignNodeBaseToWorld(node: node)

            let startPosition = SCNVector3(
                finalPosition.x,
                finalPosition.y - 0.12,
                finalPosition.z
            )
            node.position = startPosition
            node.opacity = 0.0
            view.scene.rootNode.addChildNode(node)
            placedNode = node
            isPlaced = true

            let fadeIn = SCNAction.fadeIn(duration: 0.60)
            fadeIn.timingMode = .easeInEaseOut
            let moveUp = SCNAction.move(
                to: finalPosition,
                duration: 0.60
            )
            moveUp.timingMode = .easeInEaseOut
            node.runAction(.group([fadeIn, moveUp]))
        }

        private func normalizeScale(node: SCNNode) {
            let (minVec, maxVec) = node.boundingBox
            let size = SCNVector3(
                maxVec.x - minVec.x,
                maxVec.y - minVec.y,
                maxVec.z - minVec.z
            )
            let maxAxis = max(size.x, max(size.y, size.z))
            let scale: Float = maxAxis > 0 ? 0.2 / maxAxis : 1
            node.scale = SCNVector3(scale, scale, scale)
        }

        private func alignNodeBaseToWorld(node: SCNNode) {
            let (minVec, maxVec) = node.boundingBox
            let centerX = ((minVec.x + maxVec.x) * 0.5) * node.scale.x
            let centerZ = ((minVec.z + maxVec.z) * 0.5) * node.scale.z
            let minY = minVec.y * node.scale.y

            let correction = SCNVector3(-centerX, -minY, -centerZ)
            node.childNodes.forEach { child in
                child.position = SCNVector3(
                    child.position.x + correction.x,
                    child.position.y + correction.y,
                    child.position.z + correction.z
                )
            }
        }

        @objc func takeSnapshot() {
            guard let view = sceneView else { return }
            AudioServicesPlaySystemSound(1108)
            let image = view.snapshot()
            NotificationCenter.default.post(name: .didTakeSnapshot, object: image)
        }

        @objc func toggleAutoRotate() {
            guard let node = placedNode else { return }
            if isAutoRotating {
                node.removeAction(forKey: "autoRotate")
            } else {
                let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 12)
                node.runAction(.repeatForever(rotate), forKey: "autoRotate")
            }
            isAutoRotating.toggle()
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let node = placedNode else { return }
            guard gesture.state == .changed else { return }

            let scale = Float(gesture.scale)
            node.scale = SCNVector3(
                node.scale.x * scale,
                node.scale.y * scale,
                node.scale.z * scale
            )
            gesture.scale = 1
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let node = placedNode else { return }
            guard gesture.state == .changed else { return }

            node.eulerAngles.y -= Float(gesture.rotation)
            gesture.rotation = 0
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARSCNView,
                  let node = placedNode,
                  let camera = view.pointOfView else { return }

            let translation = gesture.translation(in: view)
            let sensitivity: Float = 0.0008

            let deltaX = Float(translation.x) * sensitivity
            let deltaY = Float(-translation.y) * sensitivity

            let transform = camera.transform
            let right = SCNVector3(transform.m11, transform.m12, transform.m13)
            let up = SCNVector3(0, 1, 0)

            let move = SCNVector3(
                right.x * deltaX + up.x * deltaY,
                right.y * deltaX + up.y * deltaY,
                right.z * deltaX + up.z * deltaY
            )

            node.position = SCNVector3(
                node.position.x + move.x,
                node.position.y + move.y,
                node.position.z + move.z
            )

            gesture.setTranslation(.zero, in: view)
        }

        func teardown(view: ARSCNView) {
            NotificationCenter.default.removeObserver(self, name: .takeSnapshot, object: nil)
            NotificationCenter.default.removeObserver(self, name: .toggleAutoRotate, object: nil)
            view.session.pause()
            view.delegate = nil
            view.session.delegate = nil
        }
    }
}

#else
struct ARGLBView: View {
    var body: some View {
        Text("GLTFSceneKit が必要です")
    }
}
#endif
