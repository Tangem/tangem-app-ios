//
//  TokenListView.swift
//  Tangem
//
//  Created by Andrew Son on 09/02/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import Combine
import AlertToast

struct TokenListView: View {
    @ObservedObject var viewModel: TokenListViewModel

    var body: some View {
        ZStack {
            list

            overlay
        }
        .scrollDismissesKeyboardCompat(true)
        .navigationBarTitle(Text(viewModel.titleKey), displayMode: .automatic)
        .navigationBarItems(trailing: addCustomView)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .toast(isPresenting: $viewModel.showToast) {
            AlertToast(type: .complete(Color.tangemGreen), title: Localization.contractAddressCopiedMessage)
        }
        .searchableCompat(text: $viewModel.enteredSearchText.value)
        .background(Colors.Background.plain.edgesIgnoringSafeArea(.all))
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var list: some View {
        ScrollView {
            LazyVStack {
                if #available(iOS 15.0, *) {} else {
                    SearchBar(text: $viewModel.enteredSearchText.value, placeholder: Localization.commonSearch)
                        .padding(.horizontal, 8)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if viewModel.shouldShowAlert {
                    Text(Localization.alertManageTokensAddressesMessage)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "#848488"))
                        .cornerRadius(10)
                        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .padding(.horizontal)
                }

                divider

                ForEach(viewModel.coinViewModels) {
                    CoinView(model: $0)
                        .padding(.horizontal)

                    divider
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }

                if !viewModel.isReadonlyMode {
                    Color.clear.frame(width: 10, height: 58, alignment: .center)
                }
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding([.leading])
    }

    @ViewBuilder private var addCustomView: some View {
        if !viewModel.isReadonlyMode {
            Button(action: viewModel.openAddCustom) {
                ZStack {
                    Circle().fill(Colors.Button.primary)

                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .bold, design: .default))
                }
                .frame(width: 26, height: 26)
            }
            .animation(nil)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder private var titleView: some View {
        Text(viewModel.titleKey)
            .font(Font.system(size: 30, weight: .bold, design: .default))
            .minimumScaleFactor(0.8)
    }

    @ViewBuilder private var overlay: some View {
        if !viewModel.isReadonlyMode {
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
                    colors: [.white, .white, .white.opacity(0)],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .edgesIgnoringSafeArea(.bottom))
            }
        }
    }
}

struct AddNewTokensView_Previews: PreviewProvider {
    static var previews: some View {
        TokenListView(viewModel: .init(
            mode: .show,
            coordinator: TokenListCoordinator()
        ))
    }
}
