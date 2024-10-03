//
//  BottomSheetSearchableHeaderView.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetSearchableHeaderView: View {
    private let title: String
    private let searchText: Binding<String>

    @FocusState private var isFocused: Bool
    @State private var isSearch: Bool = false

    init(title: String, searchText: Binding<String>) {
        self.title = title
        self.searchText = searchText
    }

    var body: some View {
        VStack(spacing: .zero) {
            if isSearch {
                CustomSearchBar(searchText: searchText, placeholder: Localization.commonSearch)
                    .onEditingChanged { isEditing in
                        isSearch = isEditing
                    }
                    .focused($isFocused)
                    .transition(.opacity)
            } else {
                mainView
                    .padding(.vertical, 2)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: isSearch)
    }

    private var mainView: some View {
        ZStack(alignment: .trailing) {
            BottomSheetHeaderView(title: title)

            Button {
                isSearch = true
                isFocused = true
            } label: {
                Assets.search.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(Colors.Icon.primary1)
            }
        }
    }
}

struct BottomSheetSearchableHeaderView_Preview: PreviewProvider {
    @State private static var searchText: String = ""
    static var previews: some View {
        StatefulPreviewWrapper(searchText) { searchText in
            BottomSheetSearchableHeaderView(title: "Choose token", searchText: searchText)
        }
    }
}
