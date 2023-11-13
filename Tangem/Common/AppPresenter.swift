//
//  AppPresenter.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

class AppPresenter {
    static let shared = AppPresenter()

    private init() {}

    func showSupportChat(input: SupportChatInputModel) {
        let viewModel = SupportChatViewModel(input: input)
        let sprinklrView = SprinklrSupportChatView(viewModel: viewModel.sprinklrViewModel)
        let controller = sprinklrView.viewController

        Analytics.log(.chatScreenOpened)
        show(controller)
    }

    func showError(_ error: Error) {
        show(error.alertController)
    }

    func show(_ controller: UIViewController, delay: TimeInterval = 0.3) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(controller)
        }
    }
}
