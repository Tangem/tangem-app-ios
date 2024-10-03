//
//  SecurityModeCoordinatorView.swift
//  Tangem
//
//  Created by Alexander Osokin on 21.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SecurityModeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SecurityModeCoordinator

    var body: some View {
        if let model = coordinator.securityModeViewModel {
            SecurityModeView(viewModel: model)
                .navigationLinks(links)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.cardOperationViewModel) {
                CardOperationView(viewModel: $0)
            }
            .emptyNavigationLink()
    }
}
