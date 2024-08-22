//
//  MainBottomSheetFooterView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetFooterView: View {
    private var bottomInset: CGFloat {
        return max(
            UIApplication.safeAreaInsets.bottom - MainBottomSheetHeaderInputView.Constants.bottomInset,
            MainBottomSheetHeaderInputView.Constants.topInset - MainBottomSheetHeaderInputView.Constants.bottomInset,
            .zero
        )
    }

    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer.vertical(14.0)

            // `MainBottomSheetHeaderInputView` is used here as a dummy non-interactive placeholder,
            // by setting `allowsHitTestingForTextField` property to false
            MainBottomSheetHeaderInputView(
                searchText: .constant(""),
                isTextFieldFocused: .constant(false),
                allowsHitTestingForTextField: false
            )
            .padding(.bottom, bottomInset)
            .bottomScrollableSheetCornerRadius()
            .bottomScrollableSheetGrabber()
            .bottomScrollableSheetShadow()
        }
    }
}
