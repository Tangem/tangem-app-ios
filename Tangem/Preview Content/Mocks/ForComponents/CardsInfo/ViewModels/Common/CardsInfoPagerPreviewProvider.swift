//
//  CardsInfoPagerPreviewProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class CardsInfoPagerPreviewProvider: ObservableObject {
    @Published var pages: [CardInfoPagePreviewViewModel] = []

    private lazy var headerPreviewProvider = FakeCardHeaderPreviewProvider()

    init() {
        initializeModels()
    }

    private func initializeModels() {
        pages = headerPreviewProvider.models.map(CardInfoPagePreviewViewModel.init)
    }
}
