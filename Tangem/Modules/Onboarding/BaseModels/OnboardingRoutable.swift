//
//  OnboardingRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol OnboardingRoutable: AnyObject {
    func onboardingDidFinish()
    func closeOnboarding()
    func openSupportChat(input: SupportChatInputModel)
    func openWebView(with url: URL)
}
