//
//  MainBottomSheetFooterView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetFooterView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer(height: Constants.spacerLength, length: Constants.spacerLength)

            // `MainBottomSheetHeaderView` is used here as a dummy noninteractive placeholder
            MainBottomSheetHeaderView(searchText: .constant(""), textFieldAllowsHitTesting: false)
                .bottomScrollableSheetCornerRadius()
                .bottomScrollableSheetGrabber()
                .bottomScrollableSheetShadow()
        }
    }
}

// MARK: - Constants

private extension MainBottomSheetFooterView {
    enum Constants {
        static let spacerLength = 14.0
    }
}
