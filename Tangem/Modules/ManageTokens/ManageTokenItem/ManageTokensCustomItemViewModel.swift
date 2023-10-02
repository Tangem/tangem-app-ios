//
//  ManageTokensCustomItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 02.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ManageTokensCustomItemViewModel: Identifiable, ObservableObject {
    // MARK: - Injected Properties

    @Injected(\.tokenQuotesRepository) private var tokenQuotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published

    @Published var tokenIconInfo: TokenIconInfo?

    // MARK: - Properties

    let tokenBuilder = TokenIconInfoBuilder()

    let tokenItem: TokenItem
    let didTapAction: (TokenItem) -> Void

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        didTapAction: @escaping (TokenItem) -> Void
    ) {
        self.tokenItem = tokenItem
        self.didTapAction = didTapAction
        tokenIconInfo = tokenBuilder.build(from: tokenItem, isCustom: true)
    }
}
