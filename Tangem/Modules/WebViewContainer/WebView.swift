//
//  WebView.swift
//  Tangem
//
//  Created by Sergey Balashov on 15.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@preconcurrency import WebKit

struct WebView: UIViewRepresentable {
    var url: URL?
    var headers: [String: String] = [:]
    var popupUrl: Binding<URL?>?
    var urlActions: [String: (String) -> Void] = [:]
    var isLoading: Binding<Bool>?
    var contentInset: UIEdgeInsets?

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: configuration)
        view.isOpaque = false
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        if let contentInset {
            view.scrollView.contentInset = contentInset
        }

        if let url = url {
            AppLog.shared.debug("Loading request with url: \(url)")
            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = headers
            view.load(request)
        }

        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let urlActions: [String: (String) -> Void]
        var popupUrl: Binding<URL?>?
        var isLoading: Binding<Bool>?

        init(urlActions: [String: (String) -> Void] = [:], popupUrl: Binding<URL?>?, isLoading: Binding<Bool>?) {
            self.urlActions = urlActions
            self.popupUrl = popupUrl
            self.isLoading = isLoading
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            AppLog.shared.debug("decide for url \(String(describing: navigationAction.request.url?.absoluteString))")
            if let url = navigationAction.request.url?.absoluteString.split(separator: "?").first,
               let actionForURL = urlActions[String(url).removeLatestSlash()] {
                decisionHandler(.cancel)
                actionForURL(navigationAction.request.url!.absoluteString)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            isLoading?.wrappedValue = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading?.wrappedValue = false
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            popupUrl?.wrappedValue = navigationAction.request.url
            return nil
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(urlActions: urlActions, popupUrl: popupUrl, isLoading: isLoading)
    }
}
