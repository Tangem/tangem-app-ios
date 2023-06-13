//
//  CardInfoPageTransactionDefaultCellPreviewViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class CardInfoPageTransactionDefaultCellPreviewViewModel: ObservableObject, Identifiable {
    let id = UUID()

    var title: String {
        id.uuidString + " (\(tapCount))"
    }

    @Published private var tapCount = 0

    func onTap() {
        tapCount += 1
    }
}
