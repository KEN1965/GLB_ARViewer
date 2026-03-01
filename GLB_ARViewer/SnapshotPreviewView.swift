//
//  SnapshotPreviewView.swift
//  GLB_ARViewer
//
//  Created by Kenichi Takahama on 2026/02/11.
//

import SwiftUI

struct SnapshotPreviewView: View {
    let image: UIImage
    var onCancel: (() -> Void)? = nil
    var onSaved: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 360)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
                .clipShape(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .padding(10)

            HStack(spacing: 12) {
                Button("キャンセル") {
                    onCancel?()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.white.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button("保存") {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    onSaved?()
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.cyan)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .padding(.top, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

//#Preview {
//    SnapshotPreviewView()
//}
