//
//  BlankCard.swift
//  Tangem
//
//  Created by Andrew Son on 14.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct BlankCard: View {
    enum CardType {
        case dark
        case light

        var color: Color {
            switch self {
            case .dark: return Colors.Old.tangemGrayDark6
            case .light: return Colors.Old.tangemGrayLight4
            }
        }

        var logoColor: Color {
            switch self {
            case .dark: return .white
            case .light: return Colors.Old.tangemGrayDark5
            }
        }

        var starsColor: Color {
            switch self {
            case .dark: return Colors.Old.tangemGrayDark
            case .light: return logoColor
            }
        }
    }

    let cardType: CardType

    private let logoRatio: CGSize = .init(width: 0.239, height: 0.103)
    private let starsWidthRatio: CGFloat = 0.728
    private let maxHorizontalPadding: CGFloat = 26
    private let maxVerticalPadding: CGFloat = 30
    private let horizontalPaddingRatio: CGFloat = 0.081
    private let verticalPaddingRatio: CGFloat = 0.182

    var body: some View {
        GeometryReader { geom in
            VStack(alignment: .leading, spacing: 0) {
                let horizontalPadding = geom.size.width * horizontalPaddingRatio
                let verticalPadding = geom.size.height * verticalPaddingRatio

                Assets.tangemLogo.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(cardType.logoColor)
                    .frame(size: geom.size * logoRatio, alignment: .leading)
                    .padding(.leading, min(horizontalPadding, maxHorizontalPadding))
                    .padding(.top, min(verticalPadding, maxVerticalPadding))
                Spacer()
                Text("****  ****  ****  ****")
                    .font(Font.custom("Arial", size: 27))
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .frame(width: geom.size.width * starsWidthRatio, alignment: .leading)
                    .foregroundColor(cardType.starsColor)
                    .padding(.leading, min(horizontalPadding, maxHorizontalPadding))
                    .padding(.bottom, min(verticalPadding, maxVerticalPadding))
            }
        }
        .background(cardType.color)
        .cornerRadius(10)
    }
}

extension CGSize {
    static func * (lhs: CGSize, rhs: CGSize) -> CGSize {
        .init(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
    }
}

struct BlankCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BlankCard(cardType: .dark)
                .frame(size: .init(width: 272, height: 165))
            BlankCard(cardType: .light)
                .frame(size: .init(width: 168, height: 102))
            BlankCard(cardType: .dark)
//                .frame(size: .init(width: 272, height: 165))
        }
    }
}
