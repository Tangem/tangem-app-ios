//
//  WebSocketConnection.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor WebSocketConnection {
    private let url: URL
    private let ping: Ping
    private let timeout: TimeInterval
    
    private var _sessionWebSocketTask: Task<URLSessionWebSocketTaskWrapper, any Error>?
    private var pingTask: Task<Void, Error>?
    private var timeoutTask: Task<Void, Error>?

    /// - Parameters:
    ///   - url: A `wss` URL
    ///   - ping: The value that will be sent after a certain interval in seconds
    ///   - timeout: The value in seconds through which the connection will be terminated, if there are no new `send` calls
    init(url: URL, ping: Ping, timeout: TimeInterval) {
        self.url = url
        self.ping = ping
        self.timeout = timeout
    }
    
    func send(_ message: URLSessionWebSocketTask.Message) async throws {
        let webSocketTask = try await setupWebSocketTask()
        log("Send: \(message)")

        // Send a message
        try await webSocketTask.send(message: message)
        startPingTask()

        // Restart the disconnect timer
        startTimeoutTask()
    }

    func receive() async throws -> Data {
        guard let webSocket = try await _sessionWebSocketTask?.value else {
            throw WebSocketConnectionError.webSocketNotFound
        }
        
        // Get a message from the last response
        let response = try await webSocket.receive()
        log("Receive: \(response)")
        
        let data = try mapToData(from: response)
        return data
    }
}

// MARK: - Private

private extension WebSocketConnection {
    func startPingTask() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            guard let self else { return }

            try await Task.sleep(nanoseconds: UInt64(ping.interval) * NSEC_PER_SEC)

            try await ping()
        }
    }
    
    func startTimeoutTask() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            guard let self else { return }

            try await Task.sleep(nanoseconds: UInt64(timeout) * NSEC_PER_SEC)

            await disconnect()
        }
    }
    
    func ping() async throws {
        guard let webSocket = try await _sessionWebSocketTask?.value else {
            throw WebSocketConnectionError.webSocketNotFound
        }
        
        switch ping {
        case .message(_, let message):
            log("Send ping: \(message)")
            try await webSocket.send(message: message)

        case .plain:
            log("Send plain ping")
            try await webSocket.sendPing()
        }
        
        startPingTask()
    }
    
    func setupWebSocketTask() async throws -> URLSessionWebSocketTaskWrapper {
        if let _sessionWebSocketTask {
            let socket = try await _sessionWebSocketTask.value
            log("Return existed \(socket)")
            return socket
        }

        let connectingTask = Task {
            let socket = URLSessionWebSocketTaskWrapper(url: url)
            
            log("\(socket) start connect")
            try await socket.connect()
            log("\(socket) did open")

            return socket
        }
        
        _sessionWebSocketTask = connectingTask
        return try await connectingTask.value
    }
    
    func mapToData(from message: URLSessionWebSocketTask.Message) throws -> Data {
        switch message {
        case .data(let data):
            return data
            
        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                throw WebSocketConnectionError.invalidResponse
            }

            return data
            
        @unknown default:
            fatalError()
        }
    }
    
    func disconnect() {
        pingTask?.cancel()
        timeoutTask?.cancel()
        _sessionWebSocketTask?.cancel()
        _sessionWebSocketTask = nil
    }
    
    nonisolated func log(_ args: Any) {
        print("\(self) [\(args)]")
   }
}

// MARK: - CustomStringConvertible

extension WebSocketConnection: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self)
    }
}

// MARK: - Model

extension WebSocketConnection {
    enum Ping {
        case plain(interval: TimeInterval)
        case message(interval: TimeInterval, message: URLSessionWebSocketTask.Message)
        
        var interval: TimeInterval {
            switch self {
            case .plain(let interval):
                return interval
            case .message(let interval, _):
                return interval
            }
        }
    }
}

// MARK: - Error

enum WebSocketConnectionError: Error {
    case webSocketNotFound
    case invalidResponse
}
