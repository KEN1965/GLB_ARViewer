//
//  WebARView.swift
//  GLB_ARViewer
//
//  Created by Kenichi Takahama on 2026/02/10.
//

import SwiftUI
import WebKit

private final class WebARCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("[WKWebView] didFinish navigation")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[WKWebView] didFail navigation: \(error)")
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("[WKWebView] didFailProvisionalNavigation: \(error)")
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "log" {
            print("[JS] \(message.body)")
        }
    }
}

struct WebARView: UIViewRepresentable {

    let glbURL: URL

    func makeUIView(context: Context) -> WKWebView {
        let userContent = WKUserContentController()
        let js = """
        (function(){
          function send(msg){ try{ window.webkit.messageHandlers.log.postMessage(msg); }catch(e){} }
          var origLog = console.log; console.log = function(){ origLog.apply(console, arguments); send('[log] '+Array.from(arguments).join(' ')); };
          var origError = console.error; console.error = function(){ origError.apply(console, arguments); send('[error] '+Array.from(arguments).join(' ')); };
          window.onerror = function(msg, src, line, col, err){ send('[onerror] '+msg+' @'+src+':'+line+':'+col); };
        })();
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContent.addUserScript(script)
        userContent.add(WebARCoordinator(), name: "log")

        let config = WKWebViewConfiguration()
        config.userContentController = userContent
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        let coordinator = WebARCoordinator()
        webView.navigationDelegate = coordinator

        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black

        // Read GLB data and build a Base64 data URL with validation
        let glbData: Data?
        do {
            glbData = try Data(contentsOf: glbURL)
        } catch {
            print("[GLB] Failed to read data: \(error)")
            glbData = nil
        }
        if let d = glbData {
            print("[GLB] size bytes: \(d.count)")
            if d.count >= 4 {
                let magic = d.prefix(4)
                let hex = magic.map { String(format: "%02X", $0) }.joined(separator: " ")
                print("[GLB] magic bytes: \(hex)")
            }
        } else {
            print("[GLB] data is nil")
        }
        let isGLB: Bool = {
            guard let d = glbData, d.count >= 20 else { return false }
            let magic = d.prefix(4)
            // GLB magic should be ASCII 'glTF' -> 0x67 0x6C 0x54 0x46
            return Array(magic) == [0x67, 0x6C, 0x54, 0x46]
        }()
        if !isGLB {
            print("[GLB] Invalid header: not a GLB (expected 'glTF')")
        }

        let dataURL: String?
        if isGLB, let d = glbData, !d.isEmpty {
            let base64 = d.base64EncodedString()
            let mime = "application/octet-stream"
            dataURL = "data:\(mime);base64,\(base64)"
        } else {
            // Fallback: try to load bundled sample.glb for verification
            if let sampleURL = Bundle.main.url(forResource: "sample", withExtension: "glb"),
               let sampleData = try? Data(contentsOf: sampleURL), !sampleData.isEmpty {
                let base64 = sampleData.base64EncodedString()
                let mime = "application/octet-stream"
                dataURL = "data:\(mime);base64,\(base64)"
                print("[GLB] Fallback to bundled sample.glb (bytes: \(sampleData.count))")
            } else {
                print("[GLB] No valid input GLB and bundled sample.glb not found")
                dataURL = nil
            }
        }

        let usedFallbackJSFlag = (isGLB ? "false" : "true")

        let tempDir = FileManager.default.temporaryDirectory

        let html: String
        if let dataURL = dataURL {
            html = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <script type="module"
                src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js">
              </script>
              <style>
                body { margin: 0; background: black; color: white; font-family: -apple-system, sans-serif; }
                model-viewer { width: 100vw; height: 100vh; }
                #status { position: fixed; top: 8px; left: 8px; font-size: 12px; background: rgba(0,0,0,0.4); padding: 4px 6px; border-radius: 4px; }
              </style>
            </head>
            <body>
              <div id="status">loading...</div>
              <script>
                const usedFallback = \(usedFallbackJSFlag);
                if (usedFallback) {
                  const badge = document.createElement('div');
                  badge.textContent = 'Using bundled sample.glb';
                  badge.style.position = 'fixed';
                  badge.style.bottom = '8px';
                  badge.style.right = '8px';
                  badge.style.fontSize = '12px';
                  badge.style.background = 'rgba(255,255,255,0.15)';
                  badge.style.padding = '4px 6px';
                  badge.style.borderRadius = '4px';
                  document.body.appendChild(badge);
                }
              </script>
              <script>
                console.log('HTML loaded (data URL mode)');
              </script>
              <model-viewer
                src="\(dataURL)"
                camera-controls
                auto-rotate
                exposure="1.0"
                shadow-intensity="1"
                onload="document.getElementById('status').textContent='loaded'; console.log('model-viewer onload');"
                onerror="document.getElementById('status').textContent='error'; console.error('model-viewer onerror');">
              </model-viewer>
            </body>
            </html>
            """
        } else {
            html = """
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <style>
                body { margin: 0; background: black; color: white; font-family: -apple-system, sans-serif; display: grid; place-items: center; height: 100vh; padding: 16px; text-align: center; }
                .box { max-width: 520px; }
              </style>
            </head>
            <body>
              <div class="box">
                This file is not a valid GLB (missing 'glTF' header or too small).<br/>
                Please share a correct .glb file and try again.
              </div>
            </body>
            </html>
            """
        }

        let htmlURL = tempDir.appendingPathComponent("ar.html")

        try? html.write(to: htmlURL, atomically: true, encoding: .utf8)

        // iOSのWebXRはまだ限定的でQuick Look（USDZ）がおすすめだが、ローカルHTMLを読み込む形で実装は続ける
        // ⭐️ これが正解の読み込み方
        webView.loadFileURL(
            htmlURL,
            allowingReadAccessTo: tempDir
        )

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

//#Preview {
//    WebARView()
//}
//

