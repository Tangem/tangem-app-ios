//
//  DisclaimerViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

class DisclaimerViewModel: Identifiable {
    let webViewModel: WebViewContainerViewModel
    let id: UUID = .init()

    var showNavBarTitle: Bool { style == .details }
    var bottomOverlayHeight: CGFloat { style.bottomOverlayHeight }
    var bottomOverlayColor: Color { style.bottomOverlayColor }

    private let style: Style

    init(
        url: URL,
        style: Style
    ) {
        self.style = style
        webViewModel = .init(
            url: url,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            withNavigationBar: false,
            contentInset: style.contentInset
        )
    }
}

extension DisclaimerViewModel {
    enum Style {
        case onboarding
        case details

        var bottomOverlayHeight: CGFloat {
            switch self {
            case .details:
                return 40
            case .onboarding:
                return 170
            }
        }

        var bottomOverlayOffset: CGFloat {
            switch self {
            case .onboarding:
                return 64
            case .details:
                return .zero
            }
        }

        var bottomOverlayColor: Color {
            switch self {
            case .onboarding:
                return Colors.Background.primary
            case .details:
                return Colors.Background.plain
            }
        }

        var contentInset: UIEdgeInsets {
            return .init(top: 0, left: 0, bottom: (bottomOverlayHeight / 2) + bottomOverlayOffset, right: 0)
        }
    }
}
