//
//  DefaultSelectableRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultSelectableRowView<ID: Hashable>: View {
    private let data: DefaultSelectableRowViewModel<ID>
    private let selection: Binding<ID>

    init(data: DefaultSelectableRowViewModel<ID>, selection: Binding<ID>) {
        self.data = data
        self.selection = selection
    }

    var body: some View {
        Button(action: { selection.isActive(compare: data.id).toggle() }) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(data.title)
                        .style(Fonts.Regular.callout, color: Colors.Text.primary1)
                        .multilineTextAlignment(.leading)

                    if let subtitle = data.subtitle {
                        Text(subtitle)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 12)

                CheckIconView(isSelected: selection.isActive(compare: data.id).wrappedValue)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct DefaultSelectableRowView_Preview: PreviewProvider {
    struct ContainerView: View {
        @State private var selection: Int = 1

        var data: DefaultSelectableRowViewModel<Int> {
            DefaultSelectableRowViewModel(
                id: 1,
                title: "Long Tap",
                subtitle: Date().timeIntervalSince1970.description
            )
        }

        var body: some View {
            DefaultSelectableRowView(data: data, selection: $selection)
        }
    }

    static var previews: some View {
        ContainerView().padding()
    }
}
