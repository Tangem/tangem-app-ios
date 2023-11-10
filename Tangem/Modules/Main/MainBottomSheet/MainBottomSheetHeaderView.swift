//
//  MainBottomSheetHeaderView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A temporary entity for integration and testing, subject to change.
struct MainBottomSheetHeaderView: View {
    @Binding private var searchText: String
    private let textFieldAllowsHitTesting: Bool

    init(
        searchText: Binding<String>,
        textFieldAllowsHitTesting: Bool
    ) {
        _searchText = searchText
        self.textFieldAllowsHitTesting = textFieldAllowsHitTesting
    }

    var body: some View {
        TextField(Localization.commonSearch, text: $searchText)
            .allowsHitTesting(textFieldAllowsHitTesting)
            .frame(height: 46.0)
            .padding(.horizontal, 12.0)
            .background(Colors.Field.primary)
            .cornerRadius(14.0)
            .padding(.horizontal, 16.0)
            .padding(.top, Constants.verticalInset)
            .padding(.bottom, max(UIApplication.safeAreaInsets.bottom, Constants.verticalInset))
            .background(Colors.Background.primary)
    }
}

// MARK: - Constants

private extension MainBottomSheetHeaderView {
    enum Constants {
        static let verticalInset = 20.0
    }
}
