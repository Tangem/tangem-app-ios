//
//  WalletConnectCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WalletConnectCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WalletConnectCoordinator

    var body: some View {
        if let model = coordinator.walletConnectViewModel {
            WalletConnectView(viewModel: model)
                .sheet(item: $coordinator.qrScanViewCoordinator) {
                    QRScanViewCoordinatorView(coordinator: $0)
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
}
