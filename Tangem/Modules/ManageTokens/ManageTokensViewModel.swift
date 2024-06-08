//
//  ManageTokensViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 30/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

class ManageTokensViewModel: ObservableObject {
    var manageTokensListViewModel: ManageTokensListViewModel!

    @Published var searchText = ""
    @Published var isPendingListEmpty = true
    @Published var isSavingChanges = false
    @Published var alert: AlertBinder?

    private let adapter: ManageTokensAdapter

    private var bag = Set<AnyCancellable>()

    init(adapter: ManageTokensAdapter) {
        self.adapter = adapter

        manageTokensListViewModel = .init(
            loader: self,
            coinViewModelsPublisher: adapter.coinViewModelsPublisher
        )

        bind()
    }

    func saveChanges() {
        isSavingChanges = true

        adapter.saveChanges { [weak self] result in
            guard let self else { return }

            isSavingChanges = false
            switch result {
            case .success:
                adapter.resetAdapter()
            case .failure(let failure):
                if failure.isUserCancelled {
                    return
                }

                alert = failure.alertBinder
            }
        }
    }

    private func bind() {
        adapter
            .isPendingListsEmptyPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPendingListEmpty, on: self, ownership: .weak)
            .store(in: &bag)

        adapter
            .alertPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.alert, on: self, ownership: .weak)
            .store(in: &bag)

        $searchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                viewModel.adapter.fetch(searchText)
            }
            .store(in: &bag)
    }
}

extension ManageTokensViewModel: ManageTokensListLoader {
    var hasNextPage: Bool {
        adapter.hasNextPage
    }

    func fetch() {
        adapter.fetch(searchText)
    }
}
