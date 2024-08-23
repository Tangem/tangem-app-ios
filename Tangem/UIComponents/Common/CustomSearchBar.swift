//
//  CustomSearchBar.swift
//  Tangem
//
//  Created by skibinalexander on 13.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CustomSearchBar: View {
    @Binding var searchText: String
    private let placeholder: String
    private let keyboardType: UIKeyboardType

    @State private var isEditing: Bool = false
    private var onEditingChanged: ((_ isEditing: Bool) -> Void)?

    @FocusState private var isFocused: Bool

    init(searchText: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) {
        _searchText = searchText
        self.placeholder = placeholder
        self.keyboardType = keyboardType
    }

    var body: some View {
        HStack(spacing: 10) {
            searchBar

            if isEditing {
                cancelButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: isEditing)
    }

    private var searchBar: some View {
        HStack(spacing: 4) {
            Assets.search.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
                .frame(width: 16, height: 16)
                .padding(.all, 4)

            HStack(spacing: 4) {
                TextField(placeholder, text: $searchText, prompt: placeholderView)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onChange(of: searchText) { _ in
                        isEditing = isFocused
                        onEditingChanged?(isFocused)
                    }

                clearButton
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Colors.Field.primary)
        )
    }

    private var placeholderView: Text {
        Text(placeholder)
            .font(Fonts.Regular.subheadline)
            .foregroundColor(Colors.Text.tertiary)
    }

    private var clearButton: some View {
        Button {
            searchText = ""
        } label: {
            Assets.clear.image
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundColor(Colors.Icon.informative)
                .padding(.all, 4)
        }
        .hidden(searchText.isEmpty)
    }

    private var cancelButton: some View {
        Button {
            searchText = ""
            UIApplication.shared.endEditing()
        } label: {
            Text(Localization.commonCancel)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
        }
    }
}

extension CustomSearchBar: Setupable {
    func onEditingChanged(_ closure: ((_ isEditing: Bool) -> Void)?) -> Self {
        map { $0.onEditingChanged = closure }
    }
}

struct CustomSearchBar_Previews: PreviewProvider {
    @State private static var text: String = ""

    static var previews: some View {
        StatefulPreviewWrapper(text) { text in
            CustomSearchBar(
                searchText: text,
                placeholder: Localization.commonSearch
            )
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, max(UIApplication.safeAreaInsets.bottom, 20))
            .background(Colors.Background.primary)
        }
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)

        StatefulPreviewWrapper(text) { text in
            CustomSearchBar(
                searchText: text,
                placeholder: Localization.commonSearch
            )
            .padding(.horizontal, 16)
        }
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
