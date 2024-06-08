//
//  LegacyTokenListView.swift
//  Tangem
//
//  Created by Andrew Son on 09/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import Combine

struct LegacyTokenListView: View {
    @ObservedObject var viewModel: LegacyTokenListViewModel

    var body: some View {
        ZStack {
            list

            overlay
        }
        .scrollDismissesKeyboardCompat(.interactively)
        .navigationBarTitle(Text(Localization.addTokensTitle), displayMode: .automatic)
        .navigationBarItems(trailing: addCustomView)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .searchable(text: $viewModel.enteredSearchText.value, placement: .navigationBarDrawer(displayMode: .always))
        .keyboardType(.alphabet)
        .autocorrectionDisabled()
        .background(Colors.Background.primary.edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var list: some View {
        ScrollView {
            LazyVStack {
                if viewModel.shouldShowAlert {
                    Text(Localization.warningManageTokensLegacyDerivationMessage)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "#848488"))
                        .cornerRadius(10)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .padding(.horizontal)
                }

                divider

                ForEach(viewModel.coinViewModels) {
                    ManageTokensCoinView(model: $0)
                        .padding(.horizontal)

                    divider
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }

                Color.clear.frame(width: 10, height: 58, alignment: .center)
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding([.leading])
    }

    private var addCustomView: some View {
        Button(action: viewModel.openAddCustom) {
            ZStack {
                Circle().fill(Colors.Button.primary)

                Image(systemName: "plus")
                    .foregroundColor(Color.tangemBg)
                    .font(.system(size: 13, weight: .bold, design: .default))
            }
            .frame(width: 26, height: 26)
        }
        .animation(nil, value: 0)
    }

    private var overlay: some View {
        VStack {
            Spacer()

            MainButton(
                title: Localization.commonSaveChanges,
                isLoading: viewModel.isSaving,
                isDisabled: viewModel.isSaveDisabled,
                action: viewModel.saveChanges
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(LinearGradient(
                colors: [Colors.Background.primary, Colors.Background.primary, Colors.Background.primary.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .edgesIgnoringSafeArea(.bottom))
        }
    }
}
