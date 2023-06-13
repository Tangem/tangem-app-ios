//
//  WelcomeRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeRoutable: AnyObject {
    func openPromotion()
    func openTokensList()
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openShop()
    func openOnboarding(with input: OnboardingInput)
    func openMain(with cardModel: CardViewModel)
}
