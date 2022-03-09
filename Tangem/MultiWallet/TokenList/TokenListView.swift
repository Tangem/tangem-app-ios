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

struct TokenListView: View {
    @ObservedObject var viewModel: TokenListViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.titleKey)
                    .font(Font.system(size: 36, weight: .bold, design: .default))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                Spacer()
            }
            
            SearchBar(text: $viewModel.enteredSearchText.value, placeholder: "common_search".localized)
                .background(Color.white)
                .padding(.horizontal, 8)
            
            if viewModel.isSearching {
                Spacer()
                ActivityIndicatorView(color: .gray)
                Spacer()
            } else {
                List {
                    ForEach(viewModel.data) { section in
                        Section(header: HeaderView(text: section.name,
                                                   collapsible: section.collapsible,
                                                   isExpanded: section.expanded)
                                    .onTapGesture(perform: { viewModel.onCollapse(section) })) {
                            ForEach(section.items) { TokenView(token: $0) }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            if viewModel.showSaveButton {
                TangemButton(title: "common_save_changes", action: viewModel.saveChanges)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                   layout: .flexibleWidth,
                                                   isDisabled: viewModel.pendingTokenItems.isEmpty,
                                                   isLoading: viewModel.isLoading))
                    .padding([.leading, .trailing, .top], 16)
                    .padding(.bottom, 8)
            }
        }
        .ignoresKeyboard()
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDissapear() }
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.white)
    }
}

fileprivate struct HeaderView: View {
    var text: String
    var additionalTopPadding: CGFloat = 0
    var collapsible: Bool
    var isExpanded: Bool = true
    
    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.tangemGrayDark)
                .padding(.leading, 16)
            
            Spacer()
            if collapsible {
                Image(systemName: "chevron.down")
                    .rotationEffect(isExpanded ? .zero : Angle(degrees: -90))
                    .padding(.trailing, 16)
                    .foregroundColor(.tangemGrayDark)
                    .animation(.default.speed(2), value: isExpanded)
            }
        }
        .padding(.top, .iOS13 ?  16 : 8)
        .padding(.bottom, .iOS13 ?  8 : 4)
        .padding(.top, additionalTopPadding)
        .background(Color.white)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

fileprivate struct TokenView: View {
    let token: TokenModel
    
    private var buttonTitle: LocalizedStringKey {
        token.isAdded ? "common_added" : "common_add"
    }
    
    private var buttonStyle: TangemButtonStyle {
        TangemButtonStyle(colorStyle: token.isAdded || !token.canAdd ? .gray : .green,
                          layout: .thinHorizontal,
                          isDisabled: !token.canAdd )
    }
    
    var body: some View {
        HStack {
            token.tokenItem.iconView
                .saturation(token.tokenItem.blockchain.isTestnet ? 0 : 1.0)
                .frame(width: 40, height: 40, alignment: .center)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(token.tokenItem.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.tangemGrayDark6)
                Text(token.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemGrayDark)
            }
            
            Spacer()
            
            if token.showAddButton {
                TangemButton(title: buttonTitle, action: token.tap)
                    .buttonStyle(buttonStyle)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddNewTokensView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        TokenListView(viewModel: assembly.makeTokenListViewModel(mode: .add(cardModel: assembly.previewCardViewModel)))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
