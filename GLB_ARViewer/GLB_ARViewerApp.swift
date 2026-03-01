//
//  GLB_ARViewerApp.swift
//  GLB_ARViewer
//
//  Created by Kenichi Takahama on 2026/02/10.
//

import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct GLB_ARViewerApp: App {
    init() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        #endif
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
            }
        }
    }
