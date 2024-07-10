//
//  MarketsPortfolioTokenItemViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsPortfolioTokenItemViewModel: ObservableObject {
    // MARK: - Published Properties

    // MARK: - Private Properties
    
    private let tokenItem: TokenItem

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }
    
}
