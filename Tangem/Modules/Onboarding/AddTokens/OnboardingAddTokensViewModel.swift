//
//  OnboardingAddTokensViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 28/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt

class OnboardingAddTokensViewModel: ObservableObject {
    var manageTokensListViewModel: ManageTokensListViewModel!

    // We need to use @Published here, because our CustomSearchField doesn't work properly
    // with bindings created from CurrentValueSubject
    @Published var searchText: String = ""
    @Published var isPendingListsEmpty: Bool = false
    @Published var isSavingChanges: Bool = false

    var buttonSettings: MainButton.Settings {
        if isPendingListsEmpty {
            return .init(
                title: Localization.commonLater,
                style: .secondary,
                size: .default,
                isLoading: false,
                action: weakify(self, forFunction: OnboardingAddTokensViewModel.saveChanges)
            )
        }

        return .init(
            title: Localization.commonContinue,
            icon: .trailing(Assets.tangemIcon),
            style: .primary,
            size: .default,
            isLoading: isSavingChanges,
            action: weakify(self, forFunction: OnboardingAddTokensViewModel.saveChanges)
        )
    }

    private weak var delegate: OnboardingAddTokensDelegate?

    private let adapter: ManageTokensAdapter
    private var bag = Set<AnyCancellable>()

    init(adapter: ManageTokensAdapter, delegate: OnboardingAddTokensDelegate?) {
        self.adapter = adapter
        self.delegate = delegate
        manageTokensListViewModel = .init(loader: self, listItemsViewModelsPublisher: adapter.listItemsViewModelsPublisher)

        bind()
    }

    func saveChanges() {
        isSavingChanges = true

        if isPendingListsEmpty {
            Analytics.log(.manageTokensButtonLater)
        }

        adapter.saveChanges { [weak self] result in
            self?.isSavingChanges = false
            switch result {
            case .success:
                self?.delegate?.goToNextStep()
            case .failure(let failure):
                if failure.isUserCancelled {
                    return
                }

                self?.delegate?.showAlert(failure.alertBinder)
            }
        }
    }

    func skipAddTokens() {
        delegate?.goToNextStep()
    }

    private func bind() {
        adapter.isPendingListsEmptyPublisher
            .assign(to: \.isPendingListsEmpty, on: self, ownership: .weak)
            .store(in: &bag)

        adapter.alertPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, alert in
                guard let alert else {
                    return
                }

                viewModel.delegate?.showAlert(alert)
            }
            .store(in: &bag)

        $searchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { viewModel, searchText in
                if !searchText.isEmpty {
                    Analytics.log(.manageTokensSearched)
                }

                viewModel.adapter.fetch(searchText)
            }
            .store(in: &bag)
    }
}

extension OnboardingAddTokensViewModel: ManageTokensListLoader {
    var hasNextPage: Bool {
        adapter.hasNextPage
    }

    func fetch() {
        adapter.fetch(searchText)
    }
}
