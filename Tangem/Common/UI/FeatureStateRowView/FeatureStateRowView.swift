//
//  FeatureStateRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct FeatureStateRowView: View {
    private let viewModel: FeatureStateRowViewModel
    @State private var state: FeatureState

    init(viewModel: FeatureStateRowViewModel) {
        self.viewModel = viewModel
        state = viewModel.state.value
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.feature.name)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Release version: \(viewModel.releaseVersionInfo)")
                        .style(Fonts.Regular.caption1, color: Colors.Text.secondary)

                    Text("Default state: \(viewModel.defaultState)")
                        .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                }
            }

            Picker("", selection: $state) {
                ForEach(FeatureState.allCases) {
                    Text($0.name).tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 12)
        .connect(state: $state, to: viewModel.state)
    }
}

struct FeatureStateRowView_Preview: PreviewProvider {
    struct ContentView: View {
        @State private var state: FeatureState = .default
        var body: some View {
            FeatureStateRowView(
                viewModel: FeatureStateRowViewModel(
                    feature: .exchange,
                    enabledByDefault: true,
                    state: $state.asBindingValue
                )
            )
        }
    }

    static var previews: some View {
        ContentView()
    }
}
