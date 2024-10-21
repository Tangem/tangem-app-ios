//
//  QRScanViewCoordinatorView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct QRScanViewCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: QRScanViewCoordinator

    init(coordinator: QRScanViewCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                QRScanView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.imagePickerModel) {
                PhotoSelectorView(viewModel: $0)
                    .edgesIgnoringSafeArea(.all)
            }
    }
}
