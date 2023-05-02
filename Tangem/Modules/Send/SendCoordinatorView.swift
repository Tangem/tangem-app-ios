//
//  SendCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 16.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SendCoordinator

    var body: some View {
        ZStack {
            if let model = coordinator.sendViewModel {
                SendView(viewModel: model)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        VStack {
            NavHolder()
                .sheet(item: $coordinator.mailViewModel) {
                    MailView(viewModel: $0)
                }
                .sheet(item: $coordinator.qrScanViewModel) {
                    QRScanView(viewModel: $0)
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
}
