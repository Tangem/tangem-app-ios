//
//  SendRoutableMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendRoutableMock: SendRoutable {
    func dismiss() {}
    func openFeeExplanation(url: URL) {}
    func openMail(with dataCollector: EmailDataCollector, recipient: String) {}
    func openExplorer(url: URL) {}
    func openShareSheet(url: URL) {}
    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {}
    func openFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) {}
    func openApproveView(settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput) {}
    func openOnrampCountry(settings: OnrampCountryViewModel.Settings) {}
}
