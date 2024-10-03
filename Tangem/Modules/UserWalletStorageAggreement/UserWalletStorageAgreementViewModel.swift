//
//  UserWalletStorageAgreementViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class UserWalletStorageAgreementViewModel: ObservableObject, Identifiable {
    // MARK: - Dependencies

    private weak var coordinator: UserWalletStorageAgreementRoutable?

    init(coordinator: UserWalletStorageAgreementRoutable?) {
        self.coordinator = coordinator
    }

    func accept() {
        coordinator?.didAgreeToSaveUserWallets()
    }

    func decline() {
        coordinator?.didDeclineToSaveUserWallets()
    }
}
