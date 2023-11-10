//
//  MainBottomSheetViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// A temporary entity for integration and testing, subject to change.
final class MainBottomSheetViewModel: ObservableObject {
    // MARK: - ViewModel

    @Published var searchText: String = ""

    // MARK: - Coordinator

    @Published var bottomSheet: BottomSheetContainer_Previews.BottomSheetViewModel?

    // MARK: - Internal

    @Published var items: [String] = []

    init() {
        DispatchQueue.global().async {
            let items: [String] = (0 ..< 100).reduce(into: []) { result, _ in
                result.append(Int.random(in: 1_000 ... 1_000_000).description)
            }

            DispatchQueue.main.async {
                self.items = items
            }
        }
    }

    func dataSource() -> [String] {
        if searchText.isEmpty { return items }

        return items.filter {
            $0.contains(searchText.lowercased())
        }
    }

    func toggleItem() {
        if bottomSheet == nil {
            bottomSheet = .init { [weak self] in
                self?.bottomSheet = nil
            }
        } else {
            bottomSheet = nil
        }
    }
}
