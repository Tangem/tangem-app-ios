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

    var placeholder: String

    var body: some View {
        HStack {
            Assets.search.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
                .frame(size: .init(bothDimensions: 20))

            TextField(placeholder, text: $searchText)
                .foregroundColor(Colors.Text.primary1)
                .font(Fonts.Regular.subheadline)
                .frame(height: 20.0)
                .overlay(
                    Button(action: {
                        searchText = ""
                    }, label: {
                        Assets.clear.image
                            .renderingMode(.template)
                            .frame(size: .init(bothDimensions: 16))
                            .padding()
                            .foregroundColor(Colors.Icon.informative)
                    })
                    .frame(size: .init(bothDimensions: 44))
                    .hidden(searchText.isEmpty),
                    alignment: .trailing
                )
        }
        .padding(.vertical, 13.0)
        .padding(.horizontal, 12.0)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Colors.Field.primary)
        )
        .padding(.horizontal, 16.0)
    }
}

struct CustomSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomSearchBar(
            searchText: .constant(""),
            placeholder: Localization.commonSearch
        )
        .padding(.top, 20)
        .padding(.bottom, max(UIApplication.safeAreaInsets.bottom, 20))
        .background(Colors.Background.primary)
        .preferredColorScheme(.light)

        CustomSearchBar(
            searchText: .constant(""),
            placeholder: Localization.commonSearch
        )
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
