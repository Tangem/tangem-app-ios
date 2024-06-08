//
//  StakingView.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct StakingView: View {
    @ObservedObject private var viewModel: StakingViewModel

    init(viewModel: StakingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct StakingView_Preview: PreviewProvider {
    static let viewModel = StakingViewModel(coordinator: StakingCoordinator())

    static var previews: some View {
        StakingView(viewModel: viewModel)
    }
}
