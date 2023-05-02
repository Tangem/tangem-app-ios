//
//  OnboardingStepsBuilder.swift
//  Tangem
//
//  Created by Alexander Osokin on 06.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps
    func buildBackupSteps() -> OnboardingSteps?
}
