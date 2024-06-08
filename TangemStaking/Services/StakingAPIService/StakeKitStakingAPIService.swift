//
//  StakeKitStakingAPIService.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemFoundation

class StakeKitStakingAPIService: StakingAPIService {
    private let provider: MoyaProvider<StakeKitTarget>
    private let credential: StakingAPICredential

    private let decoder: JSONDecoder = .init()

    init(provider: MoyaProvider<StakeKitTarget>, credential: StakingAPICredential) {
        self.provider = provider
        self.credential = credential
    }

    func enabledYields() async throws -> StakeKitDTO.Yield.Enabled.Response {
        try await _request(target: .enabledYields)
    }

    func getYield(request: StakeKitDTO.Yield.Info.Request) async throws -> StakeKitDTO.Yield.Info.Response {
        try await _request(target: .getYield(request))
    }

    func enterAction(request: StakeKitDTO.Actions.Enter.Request) async throws -> StakeKitDTO.Actions.Enter.Response {
        try await _request(target: .enterAction(request))
    }
}

private extension StakeKitStakingAPIService {
    func _request<T: Decodable>(target: StakeKitTarget.Target) async throws -> T {
        let request = StakeKitTarget(apiKey: credential.apiKey, target: target)
        var response: Moya.Response

        response = try await provider.requestPublisher(request).async()

        do {
            response = try response.filterSuccessfulStatusAndRedirectCodes()
        } catch {
            if let expressError = tryMapError(target: request, response: response) {
                throw expressError
            }

            throw error
        }

        return try decoder.decode(T.self, from: response.data)
    }

    func tryMapError(target: StakeKitTarget, response: Moya.Response) -> Error? {
        do {
            let error = try JSONDecoder().decode(StakeKitDTO.APIError.self, from: response.data)
            return error
        } catch {
            return nil
        }
    }
}
