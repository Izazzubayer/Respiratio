//
//  YouTubeAudioView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//
import SwiftUI
import WebKit

struct YouTubeAudioView: UIViewRepresentable {
    let videoURL: URL
    @Binding var player: WKWebView? // reference to the webview

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: YouTubeAudioView
        init(_ parent: YouTubeAudioView) {
            self.parent = parent
        }
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        parentPlayerAssign(webView) // keep reference
        webView.scrollView.isScrollEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []

        let htmlString = """
        <!DOCTYPE html>
        <html>
        <body style="margin:0">
        <iframe id="ytplayer" type="text/html" width="1" height="1"
        src="\(videoURL.absoluteString)?enablejsapi=1&autoplay=1&controls=0&modestbranding=1&playsinline=1"
        frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func parentPlayerAssign(_ webView: WKWebView) {
        DispatchQueue.main.async {
            self.player = webView
        }
    }
}
