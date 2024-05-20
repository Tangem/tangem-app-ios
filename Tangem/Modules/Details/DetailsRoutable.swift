//
//  DetailsRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 16.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol DetailsRoutable: AnyObject {
    func openOnboardingModal(with input: OnboardingInput)
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openWalletConnect(with disabledLocalizedReason: String?)
    func openDisclaimer(at url: URL)
    func openScanCardSettings(with cardScanner: CardScanner)
    func openAppSettings()
    func openSupportChat(input: SupportChatInputModel)
    func openInSafari(url: URL)
    func openEnvironmentSetup()
    func openReferral(input: ReferralInputModel)
    func openScanCardManual()
    func dismiss()
}
