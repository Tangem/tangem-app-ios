//
//  TokenSectionView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenSectionView: View {
    let title: String?

    var body: some View {
        if let title = title {
            OrganizeTokensListSectionView(title: title, isDraggable: false)
        }
    }
}

// MARK: - Previews

struct TokenSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TokenSectionView(title: "Ethereum")

            TokenSectionView(title: nil)

            TokenSectionView(title: "A token list section header view with an extremely long title...")
        }
    }
}
