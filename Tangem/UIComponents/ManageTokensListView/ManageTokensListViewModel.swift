//
//  ManageTokensListViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class ManageTokensListViewModel: ObservableObject {
    @Published var tokenListItemModels: [ManageTokensListItemViewModel] = []

    var hasNextPage: Bool {
        loader?.hasNextPage ?? false
    }

    private weak var loader: ManageTokensListLoader?
    private let listItemsViewModelsPublisher: any Publisher<[ManageTokensListItemViewModel], Never>
    private var bag = Set<AnyCancellable>()

    init(
        loader: ManageTokensListLoader,
        listItemsViewModelsPublisher: some Publisher<[ManageTokensListItemViewModel], Never>
    ) {
        self.loader = loader
        self.listItemsViewModelsPublisher = listItemsViewModelsPublisher

        bind()
    }

    func fetch() {
        loader?.fetch()
    }

    func bind() {
        listItemsViewModelsPublisher
            .assign(to: \.tokenListItemModels, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
