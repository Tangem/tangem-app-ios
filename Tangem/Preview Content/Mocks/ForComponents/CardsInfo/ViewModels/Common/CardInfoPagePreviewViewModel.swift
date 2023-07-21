//
//  CardInfoPagePreviewViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class CardInfoPagePreviewViewModel: ObservableObject, Identifiable {
    let id = UUID()

    let header: MultiWalletCardHeaderViewModel

    @Published var sections: [CardInfoPagePreviewSection<Int>] = []

    init(
        headerViewModel: MultiWalletCardHeaderViewModel
    ) {
        header = headerViewModel
        initializeModels()
    }

    private func initializeModels() {
        let numberOfSections = Int.random(in: 1 ... Constants.maxNumberOfSections)

        sections = (0 ..< numberOfSections).map { sectionNumber in
            return .init(
                id: sectionNumber,
                items: Bool.random()
                    ? .transaction(makeTransactionSectionItems())
                    : .warning(makeWarningSectionItems())
            )
        }
    }

    private func makeWarningSectionItems() -> [CardInfoPageWarningPreviewSectionItem] {
        let numberOfRows = Int.random(in: 1 ... Constants.maxNumberOfRows)

        return (0 ..< numberOfRows).map { rowIndex in
            if Bool.random() {
                return .iconOnly(
                    CardInfoPageWarningIconOnlyCellPreviewViewModel(
                        icon: .init(systemName: "exclamationmark.triangle")
                    )
                )
            } else {
                return .iconAndTitle(
                    CardInfoPageWarningIconAndTitleCellPreviewViewModel(
                        icon: .init(systemName: "exclamationmark.triangle.fill"),
                        title: "Warning #\(rowIndex)"
                    )
                )
            }
        }
    }

    private func makeTransactionSectionItems() -> [CardInfoPageTransactionPreviewSectionItem] {
        let numberOfRows = Int.random(in: 1 ... Constants.maxNumberOfRows)

        return (0 ..< numberOfRows).map { rowIndex in
            return .default(
                CardInfoPageTransactionDefaultCellPreviewViewModel()
            )
        }
    }
}

// MARK: - Constants

private extension CardInfoPagePreviewViewModel {
    private enum Constants {
        static let maxNumberOfSections = 5
        static let maxNumberOfRows = 15
    }
}
