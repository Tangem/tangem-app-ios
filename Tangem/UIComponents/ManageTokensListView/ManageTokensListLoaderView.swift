//
//  ManageTokensListLoaderView.swift
//  Tangem
//
//  Created by Andrew Son on 09.09.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensItemSkeletonView: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonView()
                .frame(size: .init(bothDimensions: 36))
                .cornerRadiusContinuous(18)

            SkeletonView()
                .frame(size: .init(width: 70, height: 12))
                .cornerRadiusContinuous(3)

            Spacer()

            SkeletonView()
                .frame(size: .init(width: 24, height: 12))
                .cornerRadiusContinuous(3)
        }
        .padding(16)
    }
}

struct ManageTokensListLoaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 20) { _ in
                ManageTokensItemSkeletonView()
            }
        }
    }
}

#Preview {
    ManageTokensListLoaderView()
}
