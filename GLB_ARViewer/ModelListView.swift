//
//  ModelListView.swift
//  GLB_ARViewer
//
//  Created by Kenichi Takahama on 2026/02/11.
//

import SwiftUI
import SceneKit
#if canImport(GLTFSceneKit)
import GLTFSceneKit
#endif

struct RenameItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ModelListView: View {

    var onSelect: (URL) -> Void
    var onBack: () -> Void

    @State private var glbFiles: [URL] = []
    @State private var renameTarget: RenameItem?
    @State private var newName: String = ""

    private let rowHeight: CGFloat = 84
    private let rowVerticalInset: CGFloat = 12
    private let maxVisibleRows: CGFloat = 6

    var body: some View {
        ZStack {
            Color(red: 0.01, green: 0.10, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("GLB List")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))

                    Spacer()

                    // Back button area and title stay visually centered.
                    Circle()
                        .fill(.clear)
                        .frame(width: 38, height: 38)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                if glbFiles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Color(red: 0.26, green: 0.80, blue: 0.98))
                        Text("No models yet")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                        Text("Import GLTF from Home")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.18, green: 0.75, blue: 0.90))
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.10, green: 0.32, blue: 0.38).opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(red: 0.15, green: 0.75, blue: 0.90).opacity(0.4), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)
                } else {
                    List {
                        ForEach(glbFiles, id: \.self) { url in
                            Button {
                                onSelect(url)
                            } label: {
                                rowCard(for: url)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                            .contextMenu {
                                Button("名前変更") {
                                    renameTarget = RenameItem(url: url)
                                    newName = url.deletingPathExtension().lastPathComponent
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteFile(url: url)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(height: visibleListHeight)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadGLBFiles()
        }
        .sheet(item: $renameTarget) { target in
            renameSheet(for: target.url)
                .presentationBackground(Color(red: 0.01, green: 0.10, blue: 0.13))
        }

    }

    private var visibleListHeight: CGFloat {
        let visibleRows = min(CGFloat(glbFiles.count), maxVisibleRows)
        return (visibleRows * (rowHeight + rowVerticalInset)) + 12
    }

    private func rowCard(for url: URL) -> some View {
        HStack(spacing: 14) {
            if let image = loadThumbnail(for: url) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 62, height: 62)
                    .clipped()
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.08, green: 0.22, blue: 0.27))
                    .overlay {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color(red: 0.26, green: 0.80, blue: 0.98))
                    }
                    .frame(width: 62, height: 62)
            }

            Text(url.deletingPathExtension().lastPathComponent)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .frame(height: 84)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 0.10, green: 0.32, blue: 0.38).opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(red: 0.15, green: 0.75, blue: 0.90).opacity(0.28), lineWidth: 1.2)
        )
    }

    // ===== リネームUI =====
    private func renameSheet(for url: URL) -> some View {
        ZStack {
            Color(red: 0.01, green: 0.10, blue: 0.13)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                if let image = loadThumbnail(for: url) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipped()
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(red: 0.15, green: 0.75, blue: 0.90).opacity(0.5), lineWidth: 1.4)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.08, green: 0.22, blue: 0.27))
                        .frame(width: 140, height: 140)
                        .overlay {
                            Image(systemName: "cube.fill")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(Color(red: 0.26, green: 0.80, blue: 0.98))
                        }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("モデル名を変更")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))

                    Text(url.deletingPathExtension().lastPathComponent)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))

                    TextField("新しい名前", text: $newName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.10, green: 0.32, blue: 0.38).opacity(0.46))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.15, green: 0.75, blue: 0.90).opacity(0.3), lineWidth: 1.2)
                )

                HStack(spacing: 12) {
                    Button("キャンセル") {
                        renameTarget = nil
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.12))
                    )

                    Button("保存") {
                        renameFile(oldURL: url)
                        renameTarget = nil
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.01, green: 0.13, blue: 0.18))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.22, green: 0.77, blue: 0.93))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    // ===== リネーム処理 =====
    private func renameFile(oldURL: URL) {

        guard !newName.isEmpty else { return }

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let newURL = documents
            .appendingPathComponent(newName)
            .appendingPathExtension("glb")

        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)

            // サムネイルもリネーム
            let oldThumbnail = oldURL
                .deletingPathExtension()
                .appendingPathExtension("png")

            let newThumbnail = newURL
                .deletingPathExtension()
                .appendingPathExtension("png")

            if FileManager.default.fileExists(atPath: oldThumbnail.path) {
                try FileManager.default.moveItem(at: oldThumbnail, to: newThumbnail)
            }

            loadGLBFiles()

        } catch {
            print("リネーム失敗:", error)
        }
    }

    private func deleteFile(url: URL) {
        let thumbnailURL = url
            .deletingPathExtension()
            .appendingPathExtension("png")

        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            if FileManager.default.fileExists(atPath: thumbnailURL.path) {
                try FileManager.default.removeItem(at: thumbnailURL)
            }
            loadGLBFiles()
        } catch {
            print("削除失敗:", error)
        }
    }

    // ===== GLB読み込み =====
    private func loadGLBFiles() {

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documents,
                includingPropertiesForKeys: nil
            )

            glbFiles = files
                .filter { $0.pathExtension.lowercased() == "glb" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

        } catch {
            print("読み込み失敗:", error)
        }
    }

    // ===== サムネイル =====
    private func loadThumbnail(for url: URL) -> UIImage? {

        let thumbnailURL = url
            .deletingPathExtension()
            .appendingPathExtension("png")

        if FileManager.default.fileExists(atPath: thumbnailURL.path) {
            return UIImage(contentsOfFile: thumbnailURL.path)
        }

        return nil
    }
}

#Preview {
    NavigationStack {
        ModelListView(
            onSelect: { _ in },
            onBack: {}
        )
    }
}
