//
//  ManageTokensListViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class ManageTokensListViewModel: ObservableObject {
    @Published var coinViewModels: [ManageTokensCoinViewModel] = []

    var hasNextPage: Bool {
        loader?.hasNextPage ?? false
    }

    private weak var loader: ManageTokensListLoader?
    private let coinViewModelsPublisher: any Publisher<[ManageTokensCoinViewModel], Never>
    private var bag = Set<AnyCancellable>()

    init(
        loader: ManageTokensListLoader,
        coinViewModelsPublisher: some Publisher<[ManageTokensCoinViewModel], Never>
    ) {
        self.loader = loader
        self.coinViewModelsPublisher = coinViewModelsPublisher

        bind()
    }

    func fetch() {
        loader?.fetch()
    }

    func bind() {
        coinViewModelsPublisher
            .assign(to: \.coinViewModels, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
