//
//  ButtonView.swift
//  Tangem
//
//  Created by Alexander Osokin on 03.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum ButtonLayout {
    case small
    case big
    case smallVertical
    case thinHorizontal
    case wide
    case customWidth(CGFloat)
    case custom(size: CGSize)
    case flexibleWidth
    case flexible

    var idealWidth: CGFloat? {
        switch self {
        case .small:
            return 95.0
        case .big:
            return 200.0
        case .smallVertical:
            return 100.0
        case .thinHorizontal:
            return 109
        case .wide:
            return UIScreen.main.bounds.width - 80
        case .customWidth(let width):
            return width
        case .custom(let size):
            return size.width
        case .flexibleWidth, .flexible:
            return nil
        }
    }

    var maxWidth: CGFloat? {
        switch self {
        case .flexibleWidth:
            return .infinity
        default:
            return nil
        }
    }

    var height: CGFloat? {
        switch self {
        case .thinHorizontal:
            return 32
        case .custom(let size):
            return size.height
        case .flexible:
            return nil
        default:
            return defaultHeight
        }
    }

    var alignment: Alignment {
        switch self {
        case .smallVertical:
            return .vertical
        default:
            return .horizontal
        }
    }

    private var defaultHeight: CGFloat {
        AppConstants.isSmallScreen ? 44 : 46
    }
}

extension ButtonLayout {
    enum Alignment {
        case vertical
        case horizontal
    }
}

enum ButtonColorStyle {
    case black
    case gray
    case transparentWhite
    case grayAlt3

    #warning("TODO: add all buttons styles properly")
    var bgColor: Color {
        switch self {
        case .black: return .tangemGrayDark6
        case .gray: return .tangemGrayLight4
        case .transparentWhite: return .clear
        case .grayAlt3: return Colors.Button.secondary
        }
    }

    var bgPressedColor: Color {
        switch self {
        case .black: return .tangemGrayDark5
        case .gray: return .tangemGrayDark
        case .transparentWhite: return .clear
        case .grayAlt3: return Colors.Button.secondary
        }
    }

    var fgColor: Color {
        switch self {
        case .transparentWhite, .grayAlt3: return .tangemGrayDark6
        default: return .tangemBg
        }
    }

    var fgPressedColor: Color {
        switch self {
        case .transparentWhite:
            return .tangemGrayDark3
        default:
            return fgColor
        }
    }

    var indicatorColor: UIColor {
        switch self {
        case .transparentWhite, .grayAlt3: return .tangemGrayDark6
        default: return .tangemBg
        }
    }
}

@available(*, deprecated, message: "Should be replace on specific component")
struct TangemButtonStyle: ButtonStyle {
    var colorStyle: ButtonColorStyle = .black
    var layout: ButtonLayout = .small
    var font: Font = .system(size: 17, weight: .semibold, design: .default)
    var paddings: CGFloat = 8
    var cornerRadius: CGFloat = 14
    var isDisabled: Bool = false
    var isLoading: Bool = false

    @ViewBuilder private var loadingOverlay: some View {
        if isLoading {
            ZStack {
                colorStyle.bgColor
                ActivityIndicatorView(color: colorStyle.indicatorColor)
            }
        } else {
            Color.clear
        }
    }

    @ViewBuilder private var disabledOverlay: some View {
        if isDisabled {
            Color.white.opacity(0.4)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func label(for configuration: Configuration) -> some View {
        if layout.alignment == .vertical {
            VStack(alignment: .center, spacing: 0) {
                configuration.label
            }
            .padding(paddings)
        } else {
            HStack(alignment: .center, spacing: 0) {
                configuration.label
            }
            .padding(.horizontal, paddings)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        label(for: configuration)
            .font(font)
            .foregroundColor(configuration.isPressed ? colorStyle.fgPressedColor : colorStyle.fgColor)
            .frame(
                minWidth: layout.idealWidth,
                idealWidth: layout.idealWidth,
                maxWidth: layout.maxWidth,
                idealHeight: layout.height
            )
            .fixedSize(horizontal: false, vertical: true)
            .background(configuration.isPressed ? colorStyle.bgPressedColor : colorStyle.bgColor)
            .overlay(loadingOverlay)
            .overlay(disabledOverlay)
            .cornerRadius(cornerRadius)
            .allowsHitTesting(!isDisabled && !isLoading)
            .multilineTextAlignment(.center)
    }
}

extension ButtonStyle where Self == TangemButtonStyle {
    static var tangemStyle: TangemButtonStyle { .init() }
}

struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center, spacing: 16.0) {
            TangemButton(
                title: "Tangem Wide button",
                systemImage: "arrow.up",
                action: {}
            )
            .buttonStyle(TangemButtonStyle(layout: .wide))

            TangemButton(title: "Tangem custom button", action: {})
                .buttonStyle(TangemButtonStyle(
                    layout: .custom(size: CGSize(
                        width: 175,
                        height: 44
                    )),
                    font: .system(size: 18)
                ))

            TangemButton(title: "Tangem custom button", action: {})
                .buttonStyle(TangemButtonStyle(
                    layout: .customWidth(234),
                    font: .system(size: 18)
                ))

            Button(action: {}) { Text("Tap in!") }
                .buttonStyle(TangemButtonStyle())

            Button(action: {}) { Text("Tap in!") }
                .buttonStyle(TangemButtonStyle(colorStyle: .black))

            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .black,
                    layout: .big,
                    isDisabled: true
                ))

            Button(action: {}) { Text("No. Go to shop") }
                .buttonStyle(TangemButtonStyle(colorStyle: .black, isDisabled: true))

            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .transparentWhite,
                    layout: .flexibleWidth
                ))

            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .transparentWhite,
                    layout: .flexibleWidth,
                    isDisabled: true
                ))

            Button(action: {}) { Text("Go to shop") }
                .buttonStyle(TangemButtonStyle(
                    colorStyle: .grayAlt3,
                    layout: .flexibleWidth,
                    font: .system(size: 18)
                ))
        }
    }
}

struct TangemTokenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.tangemHoverButton : Color.white)
    }
}
