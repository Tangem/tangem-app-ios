//
//  AuthRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol AuthRoutable: AnyObject {
    func openOnboarding(with input: OnboardingInput)
    func openMain(with userWalletModel: UserWalletModel)
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func openScanCardManual()
}
