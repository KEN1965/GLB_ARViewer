//
//  ContentView.swift
//  GLB_ARViewer
//
//  Created by Kenichi Takahama on 2026/02/10.
//

import SceneKit
#if canImport(GLTFSceneKit)
import GLTFSceneKit
#endif
import RealityKit
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    enum ViewState: Equatable {
        case initial
        case loading
        case ar(URL)
        case arDiagnostic
        case list
    }
    
    @State private var viewState: ViewState = .initial
    @State private var showFilePicker = false
    @State private var showHowToUseSheet = false
    @State private var showSettingsSheet = false
    @Environment(\.requestReview) private var requestReview

    private struct HomeMetrics {
        let sectionSpacing: CGFloat
        let topBannerHeight: CGFloat
        let titleSize: CGFloat
        let titleBottomPadding: CGFloat
        let openCardVerticalPadding: CGFloat
        let openCardHorizontalPadding: CGFloat
        let plusCircleSize: CGFloat
        let plusIconSize: CGFloat
        let openTitleSize: CGFloat
        let openSubtitleSize: CGFloat
        let listCardHeight: CGFloat
        let listIconSize: CGFloat
        let listTextSize: CGFloat
        let listChevronSize: CGFloat
        let listHorizontalPadding: CGFloat
        let statusSize: CGFloat
        let bottomTabHeight: CGFloat
        let tabIconSize: CGFloat
        let outerHorizontalPadding: CGFloat
        let listOuterHorizontalPadding: CGFloat
    }
    
    var body: some View {
        ZStack {
            if case .loading = viewState {
                loadingView
            } else if case .ar(let url) = viewState {
                ARGLBContainerView(
                    glbURL: url,
                    onBack: {
                        viewState = .initial
                    },
                    onClose: {
                        viewState = .initial
                    }
                )
            } else if case .arDiagnostic = viewState {
                ARCameraDiagnosticContainerView {
                    viewState = .initial
                }
            } else if case .list = viewState {
                NavigationStack {
                    ModelListView(
                        onSelect: { url in
                            viewState = .loading
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                viewState = .ar(url)
                            }
                        }, onBack: {
                            viewState = .initial
                        }
                    )
                }
            } else if viewState == .initial && !showFilePicker {
                initialHomeView
            }
        }
        .fullScreenCover(isPresented: $showFilePicker) {
            DocumentPicker { url in
                
                showFilePicker = false
                viewState = .loading
                
                // 1フレーム待つ
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    importFile(url: url)
                }
            } onCancel: {
                showFilePicker = false
            }
        }
        .sheet(isPresented: $showHowToUseSheet) {
            howToUseSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettingsSheet) {
            settingsSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            if shouldShowMainTabBar {
                VStack(spacing: 8) {
                    adBannerBar
                    mainTabBar
                }
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)

                Text("AR起動中...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }

    private var initialHomeView: some View {
        GeometryReader { proxy in
            let metrics = homeMetrics(for: proxy.size)
            let cardWidth = min(proxy.size.width - (metrics.outerHorizontalPadding * 2), 330)
            let middleSpacing: CGFloat = 10
            let reservedBottom: CGFloat = metrics.bottomTabHeight + 52
            let maxOpenHeight = max(
                0,
                proxy.size.height
                - metrics.topBannerHeight
                - reservedBottom
                - metrics.listCardHeight
                - middleSpacing
                - 48
            )
            let targetOpenWidth = min(cardWidth, proxy.size.width * 0.72)
            let openCardHeight = min(targetOpenWidth * 0.8, maxOpenHeight)
            let openCardWidth = openCardHeight / 0.8

            ZStack {
                Color(red: 0.01, green: 0.10, blue: 0.13)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(red: 0.01, green: 0.10, blue: 0.13))
                        .overlay(alignment: .bottom) {
                            Text("GLB_ARViewer")
                                .font(.system(size: metrics.titleSize, weight: .bold))
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                                .foregroundStyle(.white.opacity(0.92))
                                .padding(.bottom, metrics.titleBottomPadding)
                                .padding(.bottom, 20)
                        }
                        .frame(height: metrics.topBannerHeight)
                    Spacer()
                }

                VStack(spacing: middleSpacing) {
                    Button {
                        showFilePicker = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color(red: 0.10, green: 0.32, blue: 0.38).opacity(0.62))

                            RoundedRectangle(cornerRadius: 26)
                                .stroke(Color(red: 0.15, green: 0.75, blue: 0.90).opacity(0.6), lineWidth: 2)

                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.20, green: 0.80, blue: 0.96))
                                        .frame(width: metrics.plusCircleSize, height: metrics.plusCircleSize)
                                        .shadow(color: .cyan.opacity(0.35), radius: 20)

                                    Image(systemName: "plus")
                                        .font(.system(size: metrics.plusIconSize, weight: .bold))
                                        .foregroundStyle(Color(red: 0.02, green: 0.17, blue: 0.24))
                                }
                                .padding(.bottom, 10)

                                Text("Open 3D Model")
                                    .font(.system(size: metrics.openTitleSize, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.95))

                                Text("Import GLTF")
                                    .font(.system(size: metrics.openSubtitleSize, weight: .medium))
                                    .foregroundStyle(Color(red: 0.18, green: 0.75, blue: 0.90))
                            }
                            .padding(.vertical, metrics.openCardVerticalPadding)
                            .padding(.horizontal, metrics.openCardHorizontalPadding)
                        }
                        .shadow(color: Color(red: 0.00, green: 0.95, blue: 0.95).opacity(0.18), radius: 24, y: 12)
                    }
                    .buttonStyle(.plain)
                    .frame(width: openCardWidth, height: openCardHeight)

                    Button {
                        viewState = .list
                    } label: {
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(red: 0.08, green: 0.22, blue: 0.27))
                                .overlay {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: metrics.listIconSize, weight: .bold))
                                        .foregroundStyle(Color(red: 0.26, green: 0.80, blue: 0.98))
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                                )
                                .frame(width: metrics.listIconSize * 2.2, height: metrics.listIconSize * 2.2)
                                .padding(.trailing, 10)
                                .padding(.leading, 10)

                            Text("3D Model List")
                                .font(.system(size: metrics.listTextSize, weight: .bold))
                                .foregroundStyle(.white.opacity(0.93))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: metrics.listChevronSize, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        .padding(.horizontal, metrics.listHorizontalPadding)
                        .frame(height: metrics.listCardHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.black.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.14), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(width: openCardWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.top,100)

            }
        }
    }

    private var howToUseSheet: some View {
        ZStack {
            Color(red: 0.01, green: 0.10, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("閉じる") {
                        showHowToUseSheet = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How to Use")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.bottom, 26)

                        Text("GLBモデルをARで目の前に出現することができるアプリです。")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .padding(.bottom, 26)

                        Divider().overlay(Color.white)
                            .frame(height: 1)

                        VStack(alignment: .leading, spacing: 24) {
                            Text("1.Home画面の「Open 3D Model」を押してGLBファイルを選択するとGLBがARで目の前に出現します。")
                            Text("2.カメラが起動するので、GLBを表示したい場所にiPhoneを水平にして構えてください。")
                            Text("3.AR画面では、モデルの移動・縮小・拡大できます。また、写真撮影・動画撮影でき保存もできます。")
                            Text("4.一度表示したモデルは、リストに追加されます。")
                            Text("5.リストからもAR表示できます。")
                            Text("6.モデル一覧では、左スワイプで削除、長押しで名前変更できます。")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
            }
        }
    }

    private var settingsSheet: some View {
        ZStack {
            Color(red: 0.01, green: 0.10, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("設定")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.96))
                    Spacer()

                    Button("完了") {
                        showSettingsSheet = false
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("サポート")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.52))
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            settingsActionRow(title: "フィードバックを送る") {
                                if let url = URL(string: "mailto:") {
                                    UIApplication.shared.open(url)
                                }
                            }

                            Divider()
                                .overlay(Color.white.opacity(0.14))

                            ShareLink(
                                item: "GLB_ARViewer",
                                subject: Text("GLB_ARViewer")
                            ) {
                                HStack(spacing: 14) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .regular))
                                    Text("アプリを共有")
                                        .font(.system(size: 17, weight: .medium))
                                    Spacer()
                                }
                                .foregroundStyle(Color(red: 0.22, green: 0.77, blue: 0.93))
                                .padding(.horizontal, 20)
                                .frame(height: 60)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .overlay(Color.white.opacity(0.14))

                            settingsActionRow(title: "レビューを書く") {
                                requestReview()
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )

                        Text("アプリ")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.52))
                            .padding(.horizontal, 4)

                        HStack {
                            Text("バージョン")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white.opacity(0.92))
                            Spacer()
                            Text(appVersionText)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white.opacity(0.46))
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    private func settingsActionRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                Spacer()
            }
            .foregroundStyle(Color(red: 0.22, green: 0.77, blue: 0.93))
            .padding(.horizontal, 20)
            .frame(height: 60)
        }
        .buttonStyle(.plain)
    }

    private var shouldShowMainTabBar: Bool {
        if showFilePicker {
            return false
        }
        switch viewState {
        case .initial, .list:
            return true
        default:
            return false
        }
    }

    private var isHomeTabActive: Bool {
        viewState == .initial
    }

    private var isListTabActive: Bool {
        viewState == .list
    }

    private var mainTabBar: some View {
        HStack {
            Button {
                viewState = .initial
            } label: {
                tabItem("house.fill", isActive: isHomeTabActive)
            }
            .buttonStyle(.plain)

            Button {
                viewState = .list
            } label: {
                tabItem("list.bullet", isActive: isListTabActive)
            }
            .buttonStyle(.plain)

            Button {
                showHowToUseSheet = true
            } label: {
                tabItem("questionmark.circle.fill", isActive: false)
            }
            .buttonStyle(.plain)

            Button {
                showSettingsSheet = true
            } label: {
                tabItem("gearshape.fill", isActive: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 10, y: 6)
        .padding(.horizontal, 26)
        .padding(.bottom, 8)
    }

    private var adBannerBar: some View {
        AdMobBannerView(adUnitID: bannerAdUnitID)
            .frame(height: 50)
            .frame(maxWidth: 320)
            .padding(.vertical, 4)
    }

    private func tabItem(_ iconName: String, isActive: Bool) -> some View {
        Image(systemName: iconName)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(
                isActive
                ? Color(red: 0.01, green: 0.13, blue: 0.18)
                : .white.opacity(0.88)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(isActive ? Color(red: 0.22, green: 0.77, blue: 0.93) : Color.white.opacity(0.10))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(isActive ? 0.0 : 0.25), lineWidth: 0.8)
                    )
            )
    }

    private func homeMetrics(for size: CGSize) -> HomeMetrics {
        if size.width <= 390 {
            return HomeMetrics(
                sectionSpacing: 22,
                topBannerHeight: 210,
                titleSize: 32,
                titleBottomPadding: 20,
                openCardVerticalPadding: 16,
                openCardHorizontalPadding: 12,
                plusCircleSize: 54,
                plusIconSize: 30,
                openTitleSize: 21,
                openSubtitleSize: 13,
                listCardHeight: 78,
                listIconSize: 16,
                listTextSize: 13,
                listChevronSize: 20,
                listHorizontalPadding: 14,
                statusSize: 14,
                bottomTabHeight: 50,
                tabIconSize: 20,
                outerHorizontalPadding: 44,
                listOuterHorizontalPadding: 40
            )
        }

        if size.width <= 430 {
            return HomeMetrics(
                sectionSpacing: 22,
                topBannerHeight: 230,
                titleSize: 34,
                titleBottomPadding: 22,
                openCardVerticalPadding: 18,
                openCardHorizontalPadding: 14,
                plusCircleSize: 58,
                plusIconSize: 32,
                openTitleSize: 22,
                openSubtitleSize: 14,
                listCardHeight: 82,
                listIconSize: 17,
                listTextSize: 14,
                listChevronSize: 21,
                listHorizontalPadding: 16,
                statusSize: 15,
                bottomTabHeight: 52,
                tabIconSize: 22,
                outerHorizontalPadding: 50,
                listOuterHorizontalPadding: 46
            )
        }

        return HomeMetrics(
            sectionSpacing: 24,
            topBannerHeight: 250,
            titleSize: 36,
            titleBottomPadding: 24,
            openCardVerticalPadding: 20,
            openCardHorizontalPadding: 16,
            plusCircleSize: 62,
            plusIconSize: 34,
            openTitleSize: 24,
            openSubtitleSize: 15,
            listCardHeight: 88,
            listIconSize: 18,
            listTextSize: 15,
            listChevronSize: 22,
            listHorizontalPadding: 18,
            statusSize: 16,
            bottomTabHeight: 54,
            tabIconSize: 22,
            outerHorizontalPadding: 58,
            listOuterHorizontalPadding: 54
        )
    }
    
    // =============================
    // ファイル読み込み処理
    // =============================
    
    func importFile(url originalURL: URL) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let shouldStop = originalURL.startAccessingSecurityScopedResource()
            
            defer {
                if shouldStop {
                    originalURL.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                
                let documents = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                ).first!
                
                let destinationURL = documents
                    .appendingPathComponent(originalURL.lastPathComponent)
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: originalURL, to: destinationURL)
                
                generateThumbnailImmediately(for: destinationURL)
                
                DispatchQueue.main.async {
                    viewState = .ar(destinationURL)
                }
                
            } catch {
                
                DispatchQueue.main.async {
                    viewState = .initial
                }
            }
        }
    }
    
    func generateThumbnailImmediately(for url: URL) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            do {
                let scene = try GLTFSceneSource(url: url).scene()
                
                let rootNode = SCNNode()
                scene.rootNode.childNodes.forEach { rootNode.addChildNode($0) }
                
                let (minVec, maxVec) = rootNode.boundingBox
                let size = SCNVector3(
                    maxVec.x - minVec.x,
                    maxVec.y - minVec.y,
                    maxVec.z - minVec.z
                )
                
                let maxAxis = max(size.x, max(size.y, size.z))
                let scale: Float = maxAxis > 0 ? 1.5 / maxAxis : 1
                rootNode.scale = SCNVector3(scale, scale, scale)
                
                let center = SCNVector3(
                    (minVec.x + maxVec.x) / 2,
                    (minVec.y + maxVec.y) / 2,
                    (minVec.z + maxVec.z) / 2
                )
                
                rootNode.position = SCNVector3(
                    -center.x * scale,
                     -center.y * scale,
                     -center.z * scale
                )
                
                let thumbnailScene = SCNScene()
                thumbnailScene.rootNode.addChildNode(rootNode)
                
                let cameraNode = SCNNode()
                cameraNode.camera = SCNCamera()
                cameraNode.position = SCNVector3(0, 0, 3)
                thumbnailScene.rootNode.addChildNode(cameraNode)
                
                let lightNode = SCNNode()
                lightNode.light = SCNLight()
                lightNode.light?.type = .omni
                lightNode.position = SCNVector3(5, 5, 5)
                thumbnailScene.rootNode.addChildNode(lightNode)
                
                let ambientNode = SCNNode()
                ambientNode.light = SCNLight()
                ambientNode.light?.type = .ambient
                ambientNode.light?.color = UIColor.white
                thumbnailScene.rootNode.addChildNode(ambientNode)
                
                let renderer = SCNRenderer(device: nil, options: nil)
                renderer.scene = thumbnailScene
                renderer.pointOfView = cameraNode
                
                let image = renderer.snapshot(
                    atTime: 0,
                    with: CGSize(width: 300, height: 300),
                    antialiasingMode: .multisampling4X
                )
                
                let thumbnailURL = url
                    .deletingPathExtension()
                    .appendingPathExtension("png")
                
                if let data = image.pngData() {
                    try data.write(to: thumbnailURL)
                }
                
            } catch {
                print("サムネイル生成失敗:", error)
            }
        }
    }
    
    func makeWebARHTML(glbURL: URL) -> String {
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script type="module"
        src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js">
      </script>
      <style>
        body { margin: 0; background: black; }
        model-viewer { width: 100vw; height: 100vh; }
      </style>
    </head>
    <body>
      <model-viewer
        src="\(glbURL.absoluteString)"
        ar
        ar-modes="quick-look webxr scene-viewer"
        camera-controls
        auto-rotate>
      </model-viewer>
    </body>
    </html>
    """
    }
    
}
//
#Preview {
    ContentView()
}
