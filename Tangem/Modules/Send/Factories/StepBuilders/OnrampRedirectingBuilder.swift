//
//  OnrampRedirectingBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol OnrampRedirectingInput: AnyObject {
    var selectedOnrampProvider: OnrampProvider? { get }
}

protocol OnrampRedirectingOutput: AnyObject {
    func redirectDataDidLoad(data: OnrampRedirectData)
}

struct OnrampRedirectingBuilder {
    typealias IO = (input: OnrampRedirectingInput, output: OnrampRedirectingOutput)
    typealias ReturnValue = OnrampRedirectingViewModel

    private let io: IO
    private let tokenItem: TokenItem
    private let onrampManager: OnrampManager

    init(io: IO, tokenItem: TokenItem, onrampManager: OnrampManager) {
        self.io = io
        self.tokenItem = tokenItem
        self.onrampManager = onrampManager
    }

    func makeOnrampRedirectingViewModel(coordinator: some OnrampRedirectingRoutable) -> ReturnValue {
        let interactor = makeOnrampPaymentMethodsInteractor()
        let viewModel = OnrampRedirectingViewModel(tokenItem: tokenItem, interactor: interactor, coordinator: coordinator)

        return viewModel
    }
}

// MARK: - Private

private extension OnrampRedirectingBuilder {
    func makeOnrampPaymentMethodsInteractor() -> OnrampRedirectingInteractor {
        CommonOnrampRedirectingInteractor(
            input: io.input,
            output: io.output,
            onrampManager: onrampManager
        )
    }
}

protocol OnrampRedirectingInteractor {
    var onrampProvider: OnrampProvider? { get }

    func loadRedirectData() async throws
}

class CommonOnrampRedirectingInteractor {
    private weak var input: OnrampRedirectingInput?
    private weak var output: OnrampRedirectingOutput?

    private let onrampManager: OnrampManager

    init(
        input: OnrampRedirectingInput,
        output: OnrampRedirectingOutput,
        onrampManager: OnrampManager
    ) {
        self.input = input
        self.output = output
        self.onrampManager = onrampManager
    }
}

// MARK: - OnrampRedirectingInteractor

extension CommonOnrampRedirectingInteractor: OnrampRedirectingInteractor {
    var onrampProvider: TangemExpress.OnrampProvider? {
        input?.selectedOnrampProvider
    }

    func loadRedirectData() async throws {
        guard let provider = input?.selectedOnrampProvider else {
            throw CommonError.noData
        }

        let redirectData = try await onrampManager.loadRedirectData(provider: provider)
        output?.redirectDataDidLoad(data: redirectData)
    }
}
