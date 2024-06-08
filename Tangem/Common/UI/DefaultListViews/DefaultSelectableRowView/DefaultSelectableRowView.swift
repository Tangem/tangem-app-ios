//
//  DefaultSelectableRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultSelectableRowView<ID: Hashable>: View {
    private var viewModel: DefaultSelectableRowViewModel<ID>
    private var isSelected: Binding<ID>?

    private var isSelectedProxy: Binding<Bool> {
        .init(
            get: { isSelected?.wrappedValue == viewModel.id },
            set: { _ in isSelected?.wrappedValue = viewModel.id }
        )
    }

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

// MARK: - SelectableView

extension DefaultSelectableRowView: SelectableView, Setupable {
    typealias SelectionValue = ID

    func isSelected(_ isSelected: Binding<ID>) -> Self {
        map { $0.isSelected = isSelected }
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
