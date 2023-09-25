//
//  SelectableSwappingFeeRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SelectableSwappingFeeRowView: View {
    private let viewModel: SelectableSwappingFeeRowViewModel
    @State private var isSelected: Bool

    init(viewModel: SelectableSwappingFeeRowViewModel) {
        self.viewModel = viewModel
        isSelected = viewModel.isSelected.value
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(viewModel.title)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

            Spacer()

            content
        }
        .lineLimit(1)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .contentShape(Rectangle())
        .connect(state: $isSelected, to: viewModel.isSelected)
        .onTapGesture {
            isSelected.toggle()
        }
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 4) {
            Text(viewModel.subtitle)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

            Assets.check.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 9, height: 9)
                .foregroundColor(Colors.Icon.accent)
                .opacity(isSelected ? 1 : 0)
        }
    }
}

struct SelectableSwappingFeeRowView_Previews: PreviewProvider {
    struct ContentView: View {
        @State private var isSelectedFirst: Bool = false

        var viewModels: [SelectableSwappingFeeRowViewModel] {
            [
                .init(
                    title: "Normal",
                    subtitle: "0.155 MATIC (0.145 $)",
                    isSelected: .init(get: { isSelectedFirst }, set: { isSelectedFirst = $0 })
                ),
                .init(
                    title: "Priority",
                    subtitle: "0.163 MATIC (0.156 $)",
                    isSelected: .init(get: { !isSelectedFirst }, set: { isSelectedFirst = !$0 })
                ),
            ]
        }

        var body: some View {
            ZStack {
                Colors.Background.secondary

                GroupedSection(viewModels) {
                    SelectableSwappingFeeRowView(viewModel: $0)
                }
                .padding()
            }
        }
    }

    static var previews: some View {
        ContentView()
    }
}
