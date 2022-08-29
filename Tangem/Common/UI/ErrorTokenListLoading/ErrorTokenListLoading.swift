//
//  ErrorTokenListLoading.swift
//  Tangem
//
//  Created by Sergey Balashov on 29.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ErrorTokenListLoading: View {
    let message: String
    let retry: () -> ()

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Assets.attention
                .frame(width: 42, height: 42)
                .background(Colors.Background.secondary)
                .cornerRadius(21)

            Text(message)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            Button(action: retry) {
                Text("Retry")
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Colors.Background.secondary)
                    .cornerRadius(7)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Colors.Background.primary)
        .cornerRadius(14)
    }
}

struct ErrorTokenListLoading_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            ErrorTokenListLoading(message: "An error occured while loading the tokens list.") {}
                .padding()
        }
    }
}
