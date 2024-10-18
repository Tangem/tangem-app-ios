//
//  OnrampCountryViewModel.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class OnrampCountryViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var iconURL: URL?
    @Published var title: String
    @Published var subtitle: Subtitle

    @Published var mainButtonTitle: String

    // MARK: - Dependencies

    private weak var coordinator: OnrampCountryRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        coordinator: OnrampCountryRoutable
    ) {
        iconURL = settings.countryIconURL
        title = settings.countryName
        subtitle = settings.isOnrampSupported ? .info : .notSupport
        mainButtonTitle = settings.isOnrampSupported ? "Confirm" : "Close"

        self.coordinator = coordinator

        bind()
    }

    func didTapChangeButton() {}

    func didTapMainButton() {}
}

// MARK: - Private

private extension OnrampCountryViewModel {
    func bind() {}
}

extension OnrampCountryViewModel {
    enum Subtitle: Hashable {
        case info
        case notSupport
    }
}

extension OnrampCountryViewModel {
    struct Settings {
        let countryIconURL: URL?
        let countryName: String
        let isOnrampSupported: Bool
    }
}
