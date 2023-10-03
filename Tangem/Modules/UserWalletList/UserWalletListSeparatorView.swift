//
//  UserWalletListSeparatorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListSeparatorView: View {
    var body: some View {
        if #available(iOS 15, *) {
            EmptyView()
        } else {
            separatorInternal()
                .padding(.leading, 78)
        }
    }

    @ViewBuilder
    private func separatorInternal() -> some View {
        Separator(height: .minimal, color: Colors.Stroke.primary)
    }
}
