//
//  MainBottomSheetContentViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// A temporary entity for integration and testing, subject to change.
final class MainBottomSheetContentViewModel: ObservableObject {
    // MARK: - ViewModel

    @Published var manageTokensViewModel: ManageTokensViewModel?

    // MARK: - Private

    private let coordinator: MainBottomSheetContentRoutable
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        enteredSearchTextPublisher: some Publisher<String, Never>,
        coordinator: MainBottomSheetContentRoutable
    ) {
        self.coordinator = coordinator
        manageTokensViewModel = .init(coordinator: coordinator)

        bind(enteredSearchTextPublisher: enteredSearchTextPublisher)
    }

    // MARK: - Private Implementation

    private func bind(enteredSearchTextPublisher: some Publisher<String, Never>) {
        enteredSearchTextPublisher
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] enteredSearchText in
                self?.manageTokensViewModel?.fetch(searchText: enteredSearchText)
            }
            .store(in: &bag)
    }
}
