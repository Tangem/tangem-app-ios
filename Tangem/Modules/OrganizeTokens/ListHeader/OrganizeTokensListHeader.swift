//
//  OrganizeTokensListHeader.swift
//  Tangem
//
//  Created by Andrey Fedorov on 21.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensListHeader: View {
    let viewModel: OrganizeTokensHeaderViewModel
    let horizontalInset: CGFloat
    let bottomInset: CGFloat

    var body: some View {
        OrganizeTokensHeaderView(viewModel: viewModel)
            .padding(.top, 8.0)
            .padding(.bottom, bottomInset)
            .padding(.horizontal, horizontalInset)
    }
}
