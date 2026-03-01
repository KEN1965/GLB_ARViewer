//
//  DocumentPicker.swift
//  GLB_ARViewer
//
//  Created by Kenichi Takahama on 2026/02/11.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {

    var onPick: (URL) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {

        let glbType = UTType(filenameExtension: "glb") ?? .data
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [glbType]
        )

        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        
        var onPick: (URL) -> Void
        var onCancel: () -> Void
        
        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {

            guard let url = urls.first else { return }
            guard url.pathExtension.lowercased() == "glb" else { return }

            DispatchQueue.main.async {
                self.onPick(url)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            DispatchQueue.main.async {
                self.onCancel()
            }
        }

    }
}
//
//#Preview {
//    DocumentPicker()
//}
