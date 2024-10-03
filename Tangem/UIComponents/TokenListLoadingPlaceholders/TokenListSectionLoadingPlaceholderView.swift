//
//  TokenListSectionLoadingPlaceholderView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 15.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenListSectionLoadingPlaceholderView: View {
    var body: some View {
        ZStack {
            HStack {
                SkeletonView()
                    .frame(width: 90.0, height: 18.0)
                    .cornerRadiusContinuous(3)

                Spacer()
            }
            .padding(.horizontal, 14.0)
            .padding(.vertical, 12.0)
        }
        .background(Colors.Background.primary)
    }
}

// MARK: - Previews

struct TokenListSectionLoadingPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background
                .secondary
                .ignoresSafeArea()

            VStack {
                TokenListSectionLoadingPlaceholderView()

                TokenListSectionLoadingPlaceholderView()
            }
            .infinityFrame(alignment: .top)
        }
    }
}
