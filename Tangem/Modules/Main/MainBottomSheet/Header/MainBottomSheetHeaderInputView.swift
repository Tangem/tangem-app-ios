//
//  MainBottomSheetHeaderInputView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 20.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// Header UI component containing an input field.
/// - Note: Text field focus state control is supported on iOS 15 and above.
struct MainBottomSheetHeaderInputView: View {
    @Binding var searchText: String

    let isTextFieldFocused: Binding<Bool>

    let allowsHitTestingForTextField: Bool

    var body: some View {
        if #available(iOS 15.0, *) {
            FocusableWrapperView(content: searchBar, isFocused: isTextFieldFocused)
        } else {
            searchBar
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        CustomSearchBar(
            searchText: $searchText,
            placeholder: Localization.commonSearch
        )
        .allowsHitTesting(allowsHitTestingForTextField)
        .padding(.top, Constants.verticalInset)
        .padding(.bottom, max(UIApplication.safeAreaInsets.bottom, Constants.verticalInset))
        .background(Colors.Background.primary)
    }
}

// MARK: - Auxiliary types

@available(iOS 15.0, *)
private extension MainBottomSheetHeaderInputView {
    private struct FocusableWrapperView<Content>: View where Content: View {
        private let content: Content

        @Binding private var isFocusedExternal: Bool

        @FocusState private var isFocusedInternal: Bool

        var body: some View {
            content
                .focused($isFocusedInternal)
                .onChange(of: isFocusedExternal) { newValue in
                    // External -> internal focused state sync (only if needed)
                    if isFocusedInternal != newValue {
                        isFocusedInternal = newValue
                    }
                }
                .onChange(of: isFocusedInternal) { newValue in
                    // Internal -> external focused state sync (only if needed)
                    if isFocusedExternal != newValue {
                        isFocusedExternal = newValue
                    }
                }
        }

        init(
            content: Content,
            isFocused: Binding<Bool>
        ) {
            self.content = content
            _isFocusedExternal = isFocused
        }
    }
}

// MARK: - Constants

private extension MainBottomSheetHeaderInputView {
    enum Constants {
        static let verticalInset = 20.0
    }
}
