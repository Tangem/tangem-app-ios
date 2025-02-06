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
import TangemFoundation

class CommonAPIListProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let remoteListRequestTimeout: TimeInterval = 5.0

    /// - Warning: DO NOT emit values to this subject directly, use convenience method `updateAPIListSubject(with:)`
    /// instead. This method guarantees thread safety and provides required synchronization.
    private let apiListSubject = CurrentValueSubject<APIList?, Never>(nil)

    func initialize() {
        runTask(withTimeout: remoteListRequestTimeout) { [weak self] in
            AppLogger.info(self, "onTimeout while file load")
            await self?.loadRemoteList()
        } onTimeout: { [weak self] in
            self?.loadLocalFile()
        }
    }

    private func loadRemoteList() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            AppLogger.info(self, "Attempting to load API list from server")

            let loadedList = try await tangemApiService.loadAPIList()

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
            AppLogger.info(self, "Remote API list loading and parsing time: \(remoteFileParseTime - startTime) seconds")
        } catch {
            if error is CancellationError || Task.isCancelled {
                AppLogger.info(self, "Loading API list from server was cancelled. No action required")
                return
            }

            AppLogger.error(self, "Failed to load API list from server. Attempting to read local API list.", error: error)
            loadLocalFile()
        }
    }

    private func loadLocalFile() {
        let apiList: APIList

        do {
            apiList = try APIListUtils().parseLocalAPIListJson()
        } catch {
            AppLogger.error(self, "Failed to parse local file. Publishing empty list", error: error)
            apiList = [:]
        }

        TangemFoundation.runTask(in: self) { await $0.updateAPIListSubject(with: apiList) }
    }

    @MainActor
    private func updateAPIListSubject(with value: APIList?) {
        apiListSubject.value = value
    }
}

// MARK: - CustomStringConvertible

extension CommonAPIListProvider: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self)
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
