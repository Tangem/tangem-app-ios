//
//  SendCoordinatorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SendCoordinator

    init(coordinator: SendCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                SendView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .sheet(item: $coordinator.modalWebViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .sheet(item: $coordinator.qrScanViewModel) {
                QRScanView(viewModel: $0)
                    .edgesIgnoringSafeArea(.all)
            }
    }
}
