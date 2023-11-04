//
//  MainBottomSheetViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// A temporary entity for integration and testing, subject to change.
final class MainBottomSheetViewModel: ObservableObject {
    // MARK: - ViewModel

    @Published var enteredSearchText: String = ""
    @Published var manageTokensViewModel: ManageTokensViewModel?

    // MARK: - Private

    private let coordinator: MainBottomSheetCoordinator
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(coordinator: MainBottomSheetCoordinator) {
        self.coordinator = coordinator
        manageTokensViewModel = .init(coordinator: coordinator, enteredSearchText: enteredSearchText)
    }

    // MARK: - Private Implementation

    private func bind() {
        $enteredSearchText
            .dropFirst()
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] string in
                self?.manageTokensViewModel?.fetch(searchText: string)
            }
            .store(in: &bag)
    }
}
