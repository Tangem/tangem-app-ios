//
//  LearnAndEarnAlertView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 29.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct LearnAndEarnAlertView: View {
    let title: String
    let subtitle: String
    let tapAction: () -> Void

    var body: some View {
        Button {
            tapAction()
        } label: {
            HStack(spacing: 0) {
                Assets.LearnAndEarn.oneInchLogoSmall.image
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.white)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)

                Spacer()

                Assets.chevron.image
                    .renderingMode(.template)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .background(
                            OneInchBlueGradientView(radius: 0.7 * geometry.size.width)
                                .opacity(0.4)
                                .frame(width: 10_000, height: 10_000)
                                .offset(x: -0.42 * geometry.size.width)
                        )
                        .background(
                            OneInchPinkGradientView(radius: 0.7 * geometry.size.width)
                                .opacity(0.35)
                                .frame(width: 10_000, height: 10_000)
                                .offset(x: 0.083 * geometry.size.width)
                        )
                }
            )
            .background(Color.black)
            .contentShape(Rectangle())
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LearnAndEarnAlertView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LearnAndEarnAlertView(title: "TITLE", subtitle: "Subtitle Subtitle Subtitle Subtitle Subtitle Subtitle Subtitle ", tapAction: {})
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}
