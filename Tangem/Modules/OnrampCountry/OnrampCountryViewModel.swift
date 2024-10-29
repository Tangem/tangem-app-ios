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

    let iconURL: URL?
    let title: String
    let style: Subtitle

    var mainButtonTitle: String {
        style == .info ? Localization.commonConfirm : Localization.commonClose
    }

    // MARK: - Dependencies

    private let country: OnrampCountry
    private let repository: OnrampRepository
    private weak var coordinator: OnrampCountryRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        country: OnrampCountry,
        repository: OnrampRepository,
        coordinator: OnrampCountryRoutable
    ) {
        iconURL = country.identity.image
        title = country.identity.name
        style = country.onrampAvailable ? .info : .notSupport

        self.country = country
        self.repository = repository
        self.coordinator = coordinator

        bind()
    }

    func didTapChangeButton() {
        coordinator?.openChangeCountry()
    }

    func didTapMainButton() {
        switch style {
        case .info:
            repository.saveChanges()
            coordinator?.dismissConfirmCountryView()
        case .notSupport:
            coordinator?.dismiss()
        }
    }
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
