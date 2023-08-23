//
//  OnboardingSeedPhraseImportView.swift
//  Tangem
//
//  Created by Andrew Son on 13/03/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingSeedPhraseImportView: View {
    @ObservedObject var viewModel: OnboardingSeedPhraseImportViewModel

    @State private var containerSize: CGSize = .zero
    @State private var contentSize: CGSize = .zero

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text(Localization.onboardingSeedImportMessage)
                        .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 26)

                    SeedPhraseTextView(inputProcessor: viewModel.inputProcessor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Colors.Field.primary)
                        .cornerRadiusContinuous(14)
                        .frame(minHeight: 114, maxHeight: 154)
                        .padding(.top, 20)

                    Text(viewModel.inputError ?? " ")
                        .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                SeedPhraseSuggestionsView(suggestions: viewModel.suggestions, suggestionTapped: viewModel.suggestionTapped(at:))
                    .padding(.top, 22)

                Color.clear
                    .frame(minHeight: containerSize.height - contentSize.height)

                MainButton(
                    title: Localization.commonImport,
                    icon: .trailing(Assets.tangemIcon),
                    style: .primary,
                    isLoading: false,
                    isDisabled: !viewModel.isSeedPhraseValid,
                    action: viewModel.importSeedPhrase
                )
                .padding(.all, 16)
            }
            .readGeometry(\.size) { contentSize in
                if self.contentSize == .zero {
                    self.contentSize = contentSize
                }
            }
        }
        .readGeometry(\.size) { contentSize in
            if containerSize == .zero {
                containerSize = containerSize
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .alert(item: $viewModel.errorAlert, content: { alertBinder in
            alertBinder.alert
        })
    }
}

struct OnboardingSeedPhraseImportView_Previews: PreviewProvider {
    private static let viewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        outputHandler: { _ in }
    )

    static var previews: some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
