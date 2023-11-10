//
//  ThemeSelectionView.swift
//  Tangem
//
//  Created by Andrew Son on 08/11/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ThemeSelectionView: View {
    @ObservedObject var viewModel: ThemeSelectionViewModel

    var body: some View {
        GroupedScrollView {
            SelectableGropedSection(
                viewModel.themeViewModels,
                selection: $viewModel.currentThemeOption,
                content: {
                    DefaultSelectableRowView(viewModel: $0)
                },
                footer: {
                    Text(Localization.appSettingsThemeSelectionFooter)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            )
        }
        .background(Colors.Background.secondary.ignoresSafeArea(edges: .all))
        .navigationTitle(Text(Localization.appSettingsThemeSelectorTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeSelectionView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView(content: {
            ThemeSelectionView(viewModel: .init())
        })
    }
}
