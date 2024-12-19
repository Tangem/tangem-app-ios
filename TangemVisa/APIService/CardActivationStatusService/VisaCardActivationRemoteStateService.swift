//
//  VisaCardActivationRemoteStateService.swift
//  TangemVisa
//
//  Created by Andrew Son on 16.12.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public protocol VisaCardActivationRemoteStateService {
    func loadCardActivationRemoteState(authorizationTokens: VisaAuthorizationTokens) async throws -> VisaCardActivationRemoteState
}

class CommonCardActivationRemoteStateService {
    typealias ActivationStatusService = APIService<CardActivationRemoteStateTarget, VisaAPIError>
    private let apiService: ActivationStatusService

    init(apiService: ActivationStatusService) {
        self.apiService = apiService
    }
}

extension CommonCardActivationRemoteStateService: VisaCardActivationRemoteStateService {
    func loadCardActivationRemoteState(authorizationTokens: VisaAuthorizationTokens) async throws -> VisaCardActivationRemoteState {
        let tokensUtility = AuthorizationTokensUtility()
        let stateResponse: CardActivationRemoteStateResponse = try await apiService.request(.init(
            target: .activationStatus,
            authorizationToken: tokensUtility.getAuthorizationHeader(from: authorizationTokens)
        ))
        return stateResponse.state
    }
}

struct CardActivationRemoteStateResponse: Decodable {
    let state: VisaCardActivationRemoteState
}
