//
//  UnlockUserWalletBottomSheetViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 16/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UnlockUserWalletBottomSheetDelegate: AnyObject {
    func unlockedWithBiometry()
    func userWalletUnlocked(_ userWalletModel: UserWalletModel)
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openScanCardManual()
}

class UnlockUserWalletBottomSheetViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil
    @Published var showTroubleshootingView: Bool = false

    private let userWalletModel: UserWalletModel
    private weak var delegate: UnlockUserWalletBottomSheetDelegate?

    init(userWalletModel: UserWalletModel, delegate: UnlockUserWalletBottomSheetDelegate?) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
    }

    func unlockWithBiometry() {
        Analytics.log(.buttonUnlockAllWithBiometrics)

        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            switch result {
            case .error(let error), .partial(_, let error):
                self?.error = error.alertBinder
            case .success:
                self?.delegate?.unlockedWithBiometry()
            default:
                break
            }
        }
    }

    func unlockWithCard() {
        Analytics.beginLoggingCardScan(source: .mainUnlock)
        isScannerBusy = true
        userWalletRepository.unlock(with: .card(userWalletId: userWalletModel.userWalletId, scanner: CardScannerFactory().makeDefaultScanner())) { [weak self] result in
            DispatchQueue.main.async {
                self?.isScannerBusy = false
                switch result {
                case .success(let unlockedModel):
                    self?.delegate?.userWalletUnlocked(unlockedModel)
                case .error(let error), .partial(_, let error):
                    self?.error = error.alertBinder
                case .troubleshooting:
                    Analytics.log(.cantScanTheCard, params: [.source: .main])
                    self?.showTroubleshooting()
                default:
                    break
                }
            }
        }
    }

    func showTroubleshooting() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showTroubleshootingView = true
        }
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .main])
        delegate?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .main])
        failedCardScanTracker.resetCounter()
        delegate?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient, emailType: .failedToScanCard)
    }
}
