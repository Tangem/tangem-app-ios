//
//  SendFeeView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFeeView: View {
    let namespace: Namespace.ID

    @ObservedObject var viewModel: SendFeeViewModel

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel.feeRowViewModels) {
                FeeRowView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.commonFeeSelectorFooter)
            }
            .verticalPadding(0)
            .separatorStyle(.minimum)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}

struct SendFeeView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendFeeView(namespace: namespace, viewModel: SendFeeViewModel(input: SendFeeViewModelInputMock()))
    }
}
