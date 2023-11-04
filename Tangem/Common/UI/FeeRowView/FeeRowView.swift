//
//  ExpressFeeRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeeRowView: View {
    let viewModel: FeeRowViewModel

    var body: some View {
        Button(action: viewModel.isSelected.toggle) {
            HStack(spacing: 8) {
                viewModel.option.icon.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(iconColor)

                Text(viewModel.option.title)
                    .style(font, color: Colors.Text.primary1)

                Spacer()

                Text(viewModel.subtitle)
                    .style(font, color: Colors.Text.primary1)
            }
            .padding(.vertical, 14)
        }
    }

    private var iconColor: Color {
        viewModel.isSelected.value ? Colors.Icon.accent : Colors.Icon.informative
    }

    private var font: Font {
        viewModel.isSelected.value ? Fonts.Bold.footnote : Fonts.Regular.footnote
    }
}

struct ExpressFeeRowView_Preview: PreviewProvider {
    struct ContentView: View {
        @State private var option: FeeOption = .market

        private var viewModels: [FeeRowViewModel] {
            [FeeRowViewModel(
                option: .market,
                subtitle: "0.159817 MATIC (0.22 $)",
                isSelected: .init(get: { option == .market }, set: { _ in option = .market })
            ), FeeRowViewModel(
                option: .fast,
                subtitle: "0.159817 MATIC (0.22 $)",
                isSelected: .init(get: { option == .fast }, set: { _ in option = .fast })
            )]
        }

        var body: some View {
            GroupedSection(viewModels) {
                FeeRowView(viewModel: $0)
            }
            .verticalPadding(14)
            .background(Colors.Background.secondary)
        }
    }

    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)

        ContentView()
            .preferredColorScheme(.dark)
    }
}
