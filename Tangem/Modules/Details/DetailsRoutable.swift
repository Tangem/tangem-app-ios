//
//  DetailsRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 16.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol DetailsRoutable: AnyObject {
    func openOnboardingModal(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openWalletConnect(with disabledLocalizedReason: String?)
    func openCurrencySelection()
    func openDisclaimer(at url: URL)
    func openScanCardSettings(with userWalletId: Data, sdk: TangemSdk)
    func openAppSettings()
    func openSupportChat(input: SupportChatInputModel)
    func openInSafari(url: URL)
    func openEnvironmentSetup()
    func openReferral(input: ReferralInputModel)
}
