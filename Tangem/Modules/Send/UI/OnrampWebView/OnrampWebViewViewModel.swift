//
//  OnrampWebViewViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class OnrampWebViewViewModel: ObservableObject {
    // MARK: - ViewState

    var title: String { "\(Localization.commonBuy) \(tokenItem.name)" }

    var urlActions: [String: (String) -> Void] {
        [
            successURL: { [weak self] _ in
                self?.coordinator?.dismissOnrampWebView()
            }
        ]
    }

    var url: URL { widgetURL }

    // MARK: - Dependencies

    private let tokenItem: TokenItem
    private let widgetURL: URL
    private let successURL: String
    private weak var coordinator: OnrampWebViewRoutable?

    init(
        settings: Settings,
        coordinator: OnrampWebViewRoutable
    ) {
        self.tokenItem = settings.tokenItem
        self.widgetURL = settings.widgetURL
        self.successURL = settings.successURL

        self.coordinator = coordinator
    }

    func close() {
        coordinator?.dismissOnrampWebView()
    }
}

extension OnrampWebViewViewModel {
    struct Settings {
        let tokenItem: TokenItem
        let widgetURL: URL
        let successURL: String
    }
}
