//
//  OnboardingAddTokensDelegate.swift
//  Tangem
//
//  Created by Andrew Son on 28/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingAddTokensDelegate: AnyObject {
    func goToNextStep()
    func showAlert(_ alert: AlertBinder)
}
