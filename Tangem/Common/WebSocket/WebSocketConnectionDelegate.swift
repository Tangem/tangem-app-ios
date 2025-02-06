//
//  WebSocketConnectionDelegate.swift
//  Tangem
//
//  Created by Andrew Son on 24/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension WebSocket {
    class WebSocketConnectionDelegate: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate {
        private let eventHandler: (WebSocketEvent) -> Void
        private var connectivityCheckTimer: Timer?

        init(eventHandler: @escaping (WebSocketEvent) -> Void) {
            self.eventHandler = eventHandler
        }

        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didOpenWithProtocol protocol: String?
        ) {
            connectivityCheckTimer?.invalidate()
            eventHandler(.connected)
        }

        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
            reason: Data?
        ) {
            eventHandler(.disconnected(closeCode))
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error {
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketConnectionError(source: .webSocketConnectionDelegate, error: error))
                eventHandler(.connnectionError(error))
            } else {
                // Possibly not really necessary since connection closure would likely have been reported
                // by the other delegate method, but just to be safe. We have checks in place to prevent
                // duplicated connection closing reporting anyway.
                eventHandler(.disconnected(.normalClosure))
            }
        }

        func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
            WCLogger.info(self, "waiting for connectivity...")

            // Lets not wait forever, since the user might be waiting for the connection to show in the UI.
            // It's better to show an error -if it's a new session- or else let the retry logic do its job
            DispatchQueue.main.async {
                self.connectivityCheckTimer?.invalidate()
                self.connectivityCheckTimer = Timer.scheduledTimer(
                    withTimeInterval: task.originalRequest?.timeoutInterval ?? 30,
                    repeats: false
                ) { _ in
                    // Cancelling the task should trigger an invocation to `didCompleteWithError`
                    task.cancel()
                }
            }
        }
    }
}
