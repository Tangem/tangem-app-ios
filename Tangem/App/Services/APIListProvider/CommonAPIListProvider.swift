//
//  CommonAPIListProvider.swift
//  Tangem
//
//  Created by Andrew Son on 19/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class CommonAPIListProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let remoteListRequestTimeout: TimeInterval = 5.0

    /// - Warning: DO NOT emit values to this subject directly, use convenience method `updateAPIListSubject(with:)`
    /// instead. This method guarantees thread safety and provides required synchronization.
    private let apiListSubject = CurrentValueSubject<APIList?, Never>(nil)

    func initialize() {
        runTask(withTimeout: remoteListRequestTimeout) { [weak self] in
            self?.log("onTimeout while file load")
            await self?.loadRemoteList()
        } onTimeout: { [weak self] in
            self?.loadLocalFile()
        }
    }

    private func loadRemoteList() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            log("Attempting to load API list from server")

            let loadedList: APIListDTO = [:] // try await tangemApiService.loadAPIList()

            try Task.checkCancellation()

            let apiListUtils = APIListUtils()
            var convertedRemoteAPIList = apiListUtils.convertToSDKModels(loadedList)
            let localAPIListFile: APIList = try apiListUtils.parseLocalAPIListJson()

            // Adding missing network providers to prevent case when no providers available for blockchain
            convertedRemoteAPIList.merge(localAPIListFile, uniquingKeysWith: { remote, local in
                return remote.isEmpty ? local : remote
            })

            await updateAPIListSubject(with: convertedRemoteAPIList)
            let remoteFileParseTime = CFAbsoluteTimeGetCurrent()
            log("Remote API list loading and parsing time: \(remoteFileParseTime - startTime) seconds")
        } catch {
            if error is CancellationError || Task.isCancelled {
                log("Loading API list from server was cancelled. No action required")
                return
            }

            log("Failed to load API list from server. Error: \(error).\nAttempting to read local API list.")
            loadLocalFile()
        }
    }

    private func loadLocalFile() {
        let apiList: APIList

        do {
            apiList = try APIListUtils().parseLocalAPIListJson()
        } catch {
            log("Failed to parse local file.\nReason: \(error).\nPublishing empty list")
            apiList = [:]
        }

        runTask(in: self) { await $0.updateAPIListSubject(with: apiList) }
    }

    private func log<T>(_ message: @autoclosure () -> T, function: String = #function) {
        AppLog.shared.debug("[CommonAPIListProvider, line: \(function)] - \(message())")
    }

    @MainActor
    private func updateAPIListSubject(with value: APIList?) {
        apiListSubject.value = value
    }
}

extension CommonAPIListProvider: APIListProvider {
    var apiList: APIList {
        return apiListSubject.value ?? [:]
    }

    var apiListPublisher: AnyPublisher<APIList, Never> {
        apiListSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
