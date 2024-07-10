//
//  MarketsPortfolioContainerViewModel.swift
//  Tangem
//
//  Created by skibinalexander on 09.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsPortfolioContainerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var tokenItemViewModels: [MarketsPortfolioTokenItemViewModel]
    
    // MARK: - Private Properties
    
    private var dataSource: MarketsDataSource
    private var emptyTapAction: (() -> Void)?

    // MARK: - Init

    init(tokenItems: [TokenItem], with dataSource: MarketsDataSource, emptyTapAction: (() -> Void)?) {
        self.dataSource = dataSource
        self.emptyTapAction = emptyTapAction
        
        tokenItemViewModels = tokenItems.map {
            MarketsPortfolioTokenItemViewModel(tokenItem: $0)
        }
    }

    // MARK: - Implementation

    func onEmptyTapAction() {
        emptyTapAction?()
    }
}
