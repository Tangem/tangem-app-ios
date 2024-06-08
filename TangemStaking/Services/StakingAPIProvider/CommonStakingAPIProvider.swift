//
//  CommonStakingAPIProvider.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonStakingAPIProvider: StakingAPIProvider {
    let service: StakingAPIService
    let mapper: StakeKitMapper

    init(service: StakingAPIService, mapper: StakeKitMapper) {
        self.service = service
        self.mapper = mapper
    }

    func enabledYields() async throws -> [YieldInfo] {
        let response = try await service.enabledYields()
        let yieldInfos = try response.data.map(mapper.mapToYieldInfo(from:))
        return yieldInfos
    }

    func yieldInfo(integrationId: String) async throws -> YieldInfo {
        let response = try await service.getYield(request: .init(integrationId: integrationId))
        let yieldInfo = try mapper.mapToYieldInfo(from: response)
        return yieldInfo
    }

    func enterAction(amount: Decimal, address: String, validator: String, integrationId: String) async throws {
        let response = try await service.enterAction(
            request: .init(
                addresses: .init(address: address),
                args: .init(
                    amount: amount.description,
                    validatorAddress: validator,
                    validatorAddresses: [.init(address: validator)]
                ),
                integrationId: integrationId
            )
        )
    }
}
