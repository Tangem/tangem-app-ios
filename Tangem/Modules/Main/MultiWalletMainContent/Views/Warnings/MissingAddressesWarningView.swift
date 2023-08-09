//
//  MissingAddressesWarningView.swift
//  Tangem
//
//  Created by Andrew Son on 09/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MissingAddressesWarningView: View {
    let missingAddressesCount: Int
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Assets.blueCircleWarning.image
                    .frame(size: .init(bothDimensions: 36))

                VStack(alignment: .leading, spacing: 2) {
                    Text(Localization.mainWarningMissingDerivationTitle)
                        .style(
                            Fonts.Bold.footnote,
                            color: Colors.Text.primary1
                        )

                    Text(Localization.mainWarningMissingDerivationDescription(missingAddressesCount))
                        .style(
                            Fonts.Regular.caption1,
                            color: Colors.Text.tertiary
                        )
                        .infinityFrame(axis: .horizontal, alignment: .leading)
                        .lineSpacing(2)
                }
            }

            HStack {
                MainButton(
                    title: Localization.commonGenerateAddresses,
                    icon: .trailing(Assets.tangemIcon),
                    style: .primary,
                    isLoading: isLoading,
                    action: action
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}

struct MissingAddressesWarningView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MissingAddressesWarningView(
                missingAddressesCount: 1,
                isLoading: false,
                action: {}
            )

            MissingAddressesWarningView(
                missingAddressesCount: 0,
                isLoading: false,
                action: {}
            )

            MissingAddressesWarningView(
                missingAddressesCount: 3,
                isLoading: false,
                action: {}
            )

            MissingAddressesWarningView(
                missingAddressesCount: 5,
                isLoading: true,
                action: {}
            )
        }
        .infinityFrame(axis: .vertical)
        .padding(.horizontal, 16)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
