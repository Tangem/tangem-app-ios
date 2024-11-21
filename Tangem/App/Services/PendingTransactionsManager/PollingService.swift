//
//  PollingService.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 21.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class PollingService<RequestData: Identifiable, ResponseData: Identifiable> where RequestData.ID == ResponseData.ID {
    struct Response {
        let data: ResponseData
        let hasChanges: Bool
    }

    let resultPublisher: AnyPublisher<[Response], Never>

    private let request: (RequestData) async -> ResponseData?
    private let shouldStopPolling: (ResponseData) -> Bool
    private let hasChanges: (ResponseData, ResponseData) -> Bool
    private let pollingInterval: TimeInterval

    private let resultSubject = CurrentValueSubject<[Response], Never>([])
    private var updateTask: Task<Void, Never>?

    init(
        request: @escaping (RequestData) async -> ResponseData?,
        shouldStopPolling: @escaping (ResponseData) -> Bool,
        hasChanges: @escaping (ResponseData, ResponseData) -> Bool,
        pollingInterval: TimeInterval
    ) {
        self.request = request
        self.shouldStopPolling = shouldStopPolling
        self.hasChanges = hasChanges
        self.pollingInterval = pollingInterval

        resultPublisher = resultSubject
            .eraseToAnyPublisher()
    }

    func startPolling(requests: [RequestData], force: Bool) {
        guard updateTask == nil || force else {
            return
        }

        cancelTask()

        updateTask = Task { [weak self] in
            await self?.poll(for: requests)
            self?.cancelTask()
        }
    }

    private func poll(for requests: [RequestData]) async {
        if requests.isEmpty {
            return
        }

        while !Task.isCancelled {
            var responses = [Response]()

            for requestData in requests {
                if let response = await getResponse(for: requestData) {
                    responses.append(response)
                }

                if Task.isCancelled {
                    return
                }
            }

            resultSubject.value = responses
            try? await Task.sleep(seconds: pollingInterval)
        }
    }

    private func getResponse(for requestData: RequestData) async -> Response? {
        let previousResponse = resultSubject.value
            .first { $0.data.id == requestData.id }

        if let previousResponse, shouldStopPolling(previousResponse.data) {
            return Response(data: previousResponse.data, hasChanges: false)
        }

        guard let responseData = await request(requestData) else {
            return previousResponse.map {
                Response(data: $0.data, hasChanges: false)
            }
        }

        if let previousResponse {
            return Response(
                data: responseData,
                hasChanges: hasChanges(previousResponse.data, responseData)
            )
        }

        return Response(data: responseData, hasChanges: true)
    }

    private func cancelTask() {
        updateTask?.cancel()
        updateTask = nil
    }

    deinit {
        cancelTask()
    }
}
