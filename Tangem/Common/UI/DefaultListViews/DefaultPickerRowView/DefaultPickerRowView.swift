//
//  DefaultPickerRowView.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultPickerRowView: View {
    private let viewModel: DefaultPickerRowViewModel
    @State private var selection: String

    init(viewModel: DefaultPickerRowViewModel) {
        self.viewModel = viewModel
        selection = viewModel.selection.value
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.title)
                .style(Fonts.Bold.callout, color: Colors.Text.primary1)

            Picker("", selection: $selection) {
                ForEach(viewModel.options, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 14)
        .connect(state: $selection, to: viewModel.selection)
    }
}
