//
//  WelcomeOnboardingTOSViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class WelcomeOnboardingTOSViewModel: ObservableObject {
    let tosViewModel: TOSViewModel = .init()

    private weak var delegate: WelcomeOnboardingTOSDelegate?

    init(delegate: WelcomeOnboardingTOSDelegate) {
        self.delegate = delegate
    }

    func didTapAccept() {
        AppSettings.shared.termsOfServicesAccepted.append(tosViewModel.url.absoluteString)
        delegate?.didAcceptTOS()
    }
}
