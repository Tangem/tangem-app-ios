//
//  CardInfoPageWarningPreviewSectionItem.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Example of a `List` that can contain different types of items.
enum CardInfoPageWarningPreviewSectionItem {
    case iconOnly(CardInfoPageWarningIconOnlyCellPreviewViewModel)
    case iconAndTitle(CardInfoPageWarningIconAndTitleCellPreviewViewModel)
}

// MARK: - Identifiable protocol conformance

extension CardInfoPageWarningPreviewSectionItem: Identifiable {
    var id: UUID {
        switch self {
        case .iconOnly(let viewModel):
            return viewModel.id
        case .iconAndTitle(let viewModel):
            return viewModel.id
        }
    }
}
