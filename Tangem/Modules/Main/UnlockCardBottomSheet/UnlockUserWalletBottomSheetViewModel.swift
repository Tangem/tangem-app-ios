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
    func showTroubleshooting()
}

class UnlockUserWalletBottomSheetViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil

    private let userWalletModel: UserWalletModel
    private weak var delegate: UnlockUserWalletBottomSheetDelegate?

    init(userWalletModel: UserWalletModel, delegate: UnlockUserWalletBottomSheetDelegate?) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
    }

    func unlockWithBiometry() {
        // TODO: Update anal
        //        Analytics.log(.buttonUnlockAllWithFaceID)

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
        // TODO: Update anal
        Analytics.beginLoggingCardScan(source: .myWalletsUnlock)
        isScannerBusy = true
        userWalletRepository.unlock(with: .card(userWallet: userWalletModel.userWallet)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isScannerBusy = false
                switch result {
                case .success(let unlockedModel):
                    self?.delegate?.userWalletUnlocked(unlockedModel)
                case .error(let error), .partial(_, let error):
                    self?.error = error.alertBinder
                case .troubleshooting:
                    self?.delegate?.showTroubleshooting()
                default:
                    break
                }
            }
        }
    }
}
