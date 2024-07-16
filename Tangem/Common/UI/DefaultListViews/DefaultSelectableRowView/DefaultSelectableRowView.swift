//
//  DefaultSelectableRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultSelectableRowView<ID: Hashable>: SelectableView {
    private let viewModel: DefaultSelectableRowViewModel<ID>

    var isSelected: Binding<ID>?
    var selectionId: ID { viewModel.id }

    init(viewModel: DefaultSelectableRowViewModel<ID>) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: { isSelectedProxy.wrappedValue.toggle() }) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.title)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)
                        .multilineTextAlignment(.leading)

                    if let subtitle = viewModel.subtitle {
                        Text(subtitle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 12)

                CheckIconView(isSelected: isSelectedProxy.wrappedValue)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct DefaultSelectableRowView_Preview: PreviewProvider {
    struct ContainerView: View {
        @State private var isSelected: Bool = false

        var viewModel: DefaultSelectableRowViewModel<Int> {
            DefaultSelectableRowViewModel(
                id: 1,
                title: "Long Tap",
                subtitle: Date().timeIntervalSince1970.description
            )
        }

        var body: some View {
            DefaultSelectableRowView(viewModel: viewModel)
        }
    }

    static var previews: some View {
        ContainerView().padding()
    }
}
