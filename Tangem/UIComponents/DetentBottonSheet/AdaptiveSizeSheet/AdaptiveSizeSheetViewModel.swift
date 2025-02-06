//
//  AdaptiveSizeSheetViewModel.swift
//  Tangem
//
//  Created by GuitarKitty on 16.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

final class AdaptiveSizeSheetViewModel: ObservableObject {
    @Published var contentHeight: CGFloat = 0

    var containerHeight: CGFloat = 0

    var scrollableContentBottomPadding: CGFloat {
        contentHeight > containerHeight ? defaultBottomPadding : 0
    }

    let defaultBottomPadding: CGFloat = 20
    let cornerRadius: CGFloat = 24
    let handleHeight: CGFloat = 20
}
