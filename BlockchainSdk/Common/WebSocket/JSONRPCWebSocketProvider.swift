//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor JSONRPCWebSocketProvider {
    private let url: URL
    private let connection: WebSocketConnection

    // Internal
    private var requests: [Int: Continuation] = [:]
    private var receiveTask: Task<Void, Never>?
    private var counter: Int = 0

    init(url: URL, ping: WebSocketConnection.Ping, timeoutInterval: TimeInterval) {
        self.url = url
        connection = WebSocketConnection(url: url, ping: ping, timeout: timeoutInterval)
    }

    func send<Parameter: Encodable, Result: Decodable>(
        method: String,
        parameter: Parameter,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) async throws -> Result {
        counter += 1
        let request = JSONRPC.Request(id: counter, method: method, params: parameter)
        let message = try request.string(encoder: encoder)
        try await connection.send(.string(message))

        // setup handler for message
        setupReceiveTask()

        let data: Data = try await withCheckedThrowingContinuation { continuation in
            requests.updateValue(.init(continuation: continuation), forKey: request.id)
        }

        try Task.checkCancellation()

        // Remove the fulfilled `continuation` from cache
        requests.removeValue(forKey: request.id)
        let response = try decoder.decode(JSONRPC.Response<Result, JSONRPC.APIError>.self, from: data)

        assert(request.id == response.id, "The response contains wrong id")
        BlockchainSDKLogger.info(self, "Return result \(response.result)")

        return try response.result.get()
    }

    func cancel() async {
        receiveTask?.cancel()

        for key in requests.keys {
            await requests[key]?.cancel()
            requests.removeValue(forKey: key)
        }
    }
}

// MARK: - Private

private extension JSONRPCWebSocketProvider {
    func setupReceiveTask() {
        receiveTask = Task { [weak self] in
            guard let self else { return }

            do {
                let data = try await connection.receive()
                await proceedReceive(data: data)

                // Handle next message
                await setupReceiveTask()
            } catch {
                BlockchainSDKLogger.error(self, "ReceiveTask catch error", error: error)
                await cancel()
            }
        }
    }

    func proceedReceive(data: Data) async {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let id = json?["id"] as? Int, let continuation = requests[id] {
                await continuation.resume(returning: data)
            } else {
                BlockchainSDKLogger.warning(self, "Received json: \(String(describing: json)) is not handled")
            }

        } catch {
            BlockchainSDKLogger.error(self, "Receive catch parse error", error: error)
        }
    }
}

// MARK: - HostProvider

extension JSONRPCWebSocketProvider: HostProvider {
    nonisolated var host: String { url.absoluteString }
}

// MARK: - CustomStringConvertible

extension JSONRPCWebSocketProvider: CustomStringConvertible {
    nonisolated var description: String {
        TangemFoundation.objectDescription(self)
    }
}

private actor Continuation {
    private let continuation: CheckedContinuation<Data, Error>
    private var isResumed: Bool = false

    init(continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func resume(returning data: Data) {
        guard !isResumed else { return }

        continuation.resume(returning: data)
        isResumed = true
    }

    func resume(throwing error: any Error) {
        guard !isResumed else { return }

        continuation.resume(throwing: error)
        isResumed = true
    }

    func cancel() {
        guard !isResumed else { return }

        continuation.resume(throwing: CancellationError())
        isResumed = true
    }
}
