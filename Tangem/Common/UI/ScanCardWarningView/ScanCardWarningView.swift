//
//  ScanCardWarningView.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScanCardWarningView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 12) {
                    icon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localization.mainScanCardWarningViewTitle)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text(Localization.mainScanCardWarningViewSubtitle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Assets.chevron.image
            }
            .frame(maxWidth: .infinity)
            .padding([.vertical, .horizontal], 16)
            .background(Colors.Background.primary)
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var icon: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Colors.Background.secondary)
                .frame(size: CGSize(bothDimensions: 42))
                .overlay(
                    Assets.tangemIcon.image
                        .renderingMode(.template)
                        .foregroundColor(.black)
                )

            Circle()
                .fill(Colors.Text.attention)
                .padding(3)
                .background(Colors.Background.primary)
                .frame(width: 12, height: 12)
                .cornerRadius(6)
        }
    }
}

struct ScanCardWarningView_Preview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            ScanCardWarningView {}.padding()
        }
    }
}
