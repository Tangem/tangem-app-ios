//
//  WebSocket.swift
//  Tangem
//
//  Created by Andrew Son on 26/12/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import TangemFoundation

class WebSocket {
    enum ConnectionState: String {
        case readyToConnect
        case disconnected
        case connecting
        case connected
    }

    var request: URLRequest
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?

    private let pingInterval: TimeInterval = 30
    private let timeoutInterval: TimeInterval = 20

    var isConnected: Bool { stateSubject.value == .connected }

    var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: ConnectionState {
        stateSubject.value
    }

    private var stateSubject: CurrentValueSubject<ConnectionState, Never> = .init(.readyToConnect)
    private var isWaitingForMessage: Bool = false
    private var wasConnectedAtLeastOnce: Bool = false

    private lazy var session: URLSession = {
        let delegate = WebSocketConnectionDelegate(eventHandler: { [weak self] event in
            self?.handleEvent(event)
        })
        let configuration = URLSessionConfiguration.default
        configuration.shouldUseExtendedBackgroundIdleMode = true
        configuration.waitsForConnectivity = true

        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }()

    private var bgTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    // needed to keep connection alive
    private var pingTimer: Timer?
    private var task: URLSessionWebSocketTask?
    private var connectionSetupDispatchWorkItem: DispatchWorkItem?
    // This stuff is need to find doubling write requests. If everything is OK - remove debug stuff in IOS-5937
    private let accessQueue = DispatchQueue(label: "com.tangem.WebSocket.properties", attributes: .concurrent)
    private var pendingMessagesToWrite: Set<String> = []

    private var bag = Set<AnyCancellable>()

    init(
        url: URL,
        onConnect: (() -> Void)? = nil,
        onDisconnect: ((Error?) -> Void)? = nil,
        onText: ((String) -> Void)? = nil
    ) {
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onText = onText

        request = URLRequest(url: url, timeoutInterval: timeoutInterval)

        // On actual iOS devices, request some additional background execution time to the OS
        // each time that the app moves to background. This allows us to continue running for
        // around 30 secs in the background instead of having the socket killed instantly, which
        // solves the issue of connecting a wallet and a dApp both on the same device.
        // See https://github.com/WalletConnect/WalletConnectSwift/pull/81#issuecomment-1175931673

        NotificationCenter.default
            .publisher(for: UIScene.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.requestBackgroundExecutionTime()
            })
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIScene.didActivateNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.endBackgroundTask()
            })
            .store(in: &bag)
    }

    deinit {
        session.invalidateAndCancel()
        invalidateTimer()
    }

    func connect() {
        log("Attempting to connect WebSocket with state \(stateSubject.value) to \(String(describing: request.url))")
        scheduleConnectionSetup()
    }

    func disconnect() {
        Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketDisconnected(closeCode: "Disconnect function", connectionState: "Before disconnect() execution: \(stateSubject.value.rawValue)"))
        invalidateTimer()
        stateSubject.value = .disconnected
        isWaitingForMessage = false
        if task == nil {
            return
        }

        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    func write(string text: String, completion: (() -> Void)?) {
        // Crash happens when completion is called multiple times for single handler.
        // This cause sending more than one `resume()` in continuation inside WC library
        let isMessagePendingToWrite = accessQueue.sync { pendingMessagesToWrite.contains(text) }
        if isMessagePendingToWrite {
            Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.attemptingToWriteMessageMultipleTimes)
            log("Attempting to write same message multiple times. \n\(text)")
            return
        }

        guard isConnected else {
            // We need to send completion event, because otherwise WC2 library will stuck and won't work anymore...
            completion?()
            return
        }

        accessQueue.async(flags: .barrier) { [weak self] in
            self?.pendingMessagesToWrite.insert(text)
        }

        log("Writing text: \(text) to socket")
        task?.send(.string(text)) { [weak self] error in
            guard let self else { return }
            if let error = error {
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketConnectionError(source: .send, error: error))
                handleEvent(.connnectionError(error))
            } else {
                handleEvent(.messageSent(text))
            }
            completion?()
            accessQueue.async(flags: .barrier) {
                self.pendingMessagesToWrite.remove(text)
            }
        }
    }

    private func log(_ message: String) {
        WCLog.info(self, message)
    }

    private func receive() {
        guard let task = task else { return }

        // We don't want to setup another `receive` subscription
        if isWaitingForMessage {
            return
        }

        isWaitingForMessage = true
        task.receive { [weak self] result in
            self?.isWaitingForMessage = false
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self?.log("Received message is string message. Message text \(text). Handling received message")
                    self?.handleEvent(.messageReceived(text))
                }
                self?.receive()
            case .failure(let error):
                self?.log("Socket receive failure message with error: \(error)")
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketConnectionError(source: .receive, error: error))
                self?.handleEvent(.connnectionError(error))
            }
        }
    }

    private func sendPing() {
        guard isConnected else { return }

        task?.sendPing(pongReceiveHandler: { [weak self] error in
            if let error {
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketConnectionError(source: .pingPong, error: error))
                self?.handleEvent(.connnectionError(error))
                return
            }

            self?.handleEvent(.pongReceived)
        })
        handleEvent(.pingSent)
    }

    private func handleEvent(_ event: WebSocketEvent) {
        switch event {
        case .connected:
            log("Receive connected event")
            stateSubject.value = .connected
            setupPingTimer()
            Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketConnected)
            onConnect?()
        case .disconnected(let closeCode):
            let closeCodeRawValue = String(describing: closeCode.rawValue)
            Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketDisconnected(
                closeCode: closeCodeRawValue,
                connectionState: stateSubject.value.rawValue
            ))

            log("Receive disconnect event. Close code: \(closeCodeRawValue)")
            guard isConnected else { break }

            disconnect()

            var error: Error?
            switch closeCode {
            case .normalClosure:
                // If we receive normal closure disconnection code it means that it was
                // initiated outside, so we don't need to notify onDisconnect
                log("💥💥💥 disconnected (normal closure)")
                return
            case .abnormalClosure, .goingAway:
                log("💥💥💥 disconnected close code (peer disconnected) - \(closeCodeRawValue)")
                error = WebSocketError.peerDisconnected
            default:
                log("💥💥💥 disconnected with not specified close code - \(closeCodeRawValue)")
                error = WebSocketError.closedUnexpectedly
            }

            notifyOnDisconnectOnMainThread(with: error)
        case .messageReceived(let text):
            Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.webSocketReceiveText(connectionState: stateSubject.value.rawValue))
            onText?(text)
        case .messageSent(let text):
            log("==> Message successfully sent \(text)")
        case .pingSent:
            log("==> Ping sent")
        case .pongReceived:
            log("<== Pong received")
        case .connnectionError(let error):
            // We need to check if task is still running, and if not - recreate it and start observing messages
            // Otherwise WC will stuck with not connected state, and only app restart will fix this problem
            log("Connection error: \(error.localizedDescription)")
            let nsError = error as NSError
            if nsError.code == -1011 {
                disconnect()
                notifyOnDisconnectOnMainThread(with: nsError)
            }

            if task?.state != .running {
                log("URLSessionWebSocketTask is not running. Resetting WebSocket state and attempting to reconnect")
                stateSubject.value = .disconnected
                connect()
                return
            }
            log("URLSessionWebSocketTask is running, no action is needed")
        }
    }

    private func requestBackgroundExecutionTime() {
        if bgTaskIdentifier != .invalid {
            endBackgroundTask()
        }

        bgTaskIdentifier = UIApplication.shared.beginBackgroundTask(
            withName: "WebSocketConnection-bgTime"
        ) { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard bgTaskIdentifier != .invalid else { return }

        UIApplication.shared.endBackgroundTask(bgTaskIdentifier)
        bgTaskIdentifier = .invalid
    }

    private func notifyOnDisconnectOnMainThread(with error: Error?) {
        if Thread.isMainThread {
            onDisconnect?(error)
            return
        }

        // Need to switch to main thread because WC 2.0 library accessing to
        // some of the UIApplication components from current thread.
        DispatchQueue.main.async {
            self.onDisconnect?(error)
        }
    }

    private func setupPingTimer() {
        DispatchQueue.main.async {
            self.invalidateTimer()
            self.pingTimer = Timer.scheduledTimer(
                withTimeInterval: self.pingInterval,
                repeats: true
            ) { [weak self] timer in
                self?.sendPing()
            }
        }
    }

    // Some crash logs and debug events indicating that there are multiple sequentials disconnect/connect requests
    // This function attempting to address this issue. Added debug log events to see if it helps...
    private func scheduleConnectionSetup() {
        log("Attempting to schedule connection setup: \(String(describing: request.url))")
        Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.connectionSetupMessage(message: "Attempting to schedule connection setup"))
        guard connectionSetupDispatchWorkItem == nil else {
            log("Connection setup already scheduled, no need to reschedule")
            Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.connectionSetupMessage(message: "Connection setup already scheduled, no need to reschedule"))
            return
        }

        let connectionSetupDelay: TimeInterval = wasConnectedAtLeastOnce ? 1 : 0
        log("Scheduling connection setup. Delay: \(connectionSetupDelay)")
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, stateSubject.value == .disconnected || stateSubject.value == .readyToConnect else {
                self?.log("No need to setup web socket connection. State: \(self?.stateSubject.value.rawValue ?? "self is nil")")
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.connectionSetupMessage(message: "No need to setup web socket connection. State: \(self?.stateSubject.value.rawValue ?? "self is nil")"))
                self?.connectionSetupDispatchWorkItem = nil
                return
            }

            // If state is `notConnected` then task shouldn't exist
            if task != nil {
                Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.connectionSetupMessage(message: "WebSocketTask is not nil, disconnecting old task"))
                disconnect()
            }
            stateSubject.value = .connecting
            task = session.webSocketTask(with: request)
            task?.resume()
            receive()
            connectionSetupDispatchWorkItem = nil
            Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.connectionSetupMessage(message: "Finished connection setup"))
            wasConnectedAtLeastOnce = true
            log("Scheduled connection setup finished")
        }
        connectionSetupDispatchWorkItem = workItem

        Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.connectionSetupMessage(message: "Adding message to global queue"))
        DispatchQueue.global().asyncAfter(deadline: .now() + connectionSetupDelay, execute: workItem)
    }

    /// `invalidate()` should be called from the same thread where it is was setup
    /// https://developer.apple.com/documentation/foundation/timer/1415405-invalidate#
    private func invalidateTimer() {
        func invalidate() {
            if pingTimer != nil {
                pingTimer?.invalidate()
                pingTimer = nil
            }
        }

        if Thread.isMainThread {
            log("Attempting to invalidate ping timer from main thread.")
            invalidate()
            return
        }

        log("Attempting to invalidate ping timer from different thread. Switching to main thread")
        DispatchQueue.main.async {
            invalidate()
        }
    }
}

// MARK: - CustomStringConvertible

extension WebSocket: CustomStringConvertible {
    var description: String { TangemFoundation.objectDescription(self) }
}
