//
//  OnrampProvidersView.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampProvidersView: View {
    @ObservedObject private var viewModel: OnrampProvidersViewModel

    init(viewModel: OnrampProvidersViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct OnrampProvidersView_Preview: PreviewProvider {
    static let viewModel = OnrampProvidersViewModel(coordinator: OnrampProvidersCoordinator())

    static var previews: some View {
        OnrampProvidersView(viewModel: viewModel)
    }
}
