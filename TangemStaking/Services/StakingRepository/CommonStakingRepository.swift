//
//  CommonStakingRepository.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonStakingRepository {
    private let provider: StakingAPIProvider
    private let logger: Logger

    private var updatingTask: Task<Void, Never>?
    private var availableYields: CurrentValueSubject<[YieldInfo]?, Never> = .init(nil)

    init(provider: StakingAPIProvider, logger: Logger) {
        self.provider = provider
        self.logger = logger
    }
}

extension CommonStakingRepository: StakingRepository {
    var enabledYieldsPuiblisher: AnyPublisher<[YieldInfo], Never> {
        availableYields.compactMap { $0 }.eraseToAnyPublisher()
    }

    func updateEnabledYields(withReload: Bool) {
        if withReload {
            availableYields.value = nil
        }

        guard availableYields.value == nil else {
            return
        }

        updatingTask?.cancel()
        updatingTask = Task { [weak self] in
            do {
                self?.availableYields.value = try await self?.provider.enabledYields()
            } catch {
                self?.logger.error(error)
            }
        }
    }

    func getYield(id: String) -> YieldInfo? {
        return availableYields.value?.first(where: { $0.id == id })
    }

    func getYield(item: StakingTokenItem) -> YieldInfo? {
        return availableYields.value?.first(where: { $0.item == item })
    }
}
