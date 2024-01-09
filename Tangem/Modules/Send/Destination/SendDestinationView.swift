//
//  SendDestinationView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationView: View {
    let namespace: Namespace.ID
    @ObservedObject var viewModel: SendDestinationViewModel

    var body: some View {
        GroupedScrollView {
            if let addressViewModel = viewModel.addressViewModel {
                SendDestinationTextView(viewModel: addressViewModel)
            }

            if let additionalFieldViewModel = viewModel.additionalFieldViewModel {
                SendDestinationTextView(viewModel: additionalFieldViewModel)
            }

            if let suggestedDestinationViewModel = viewModel.suggestedDestinationViewModel {
                SendSuggestedDestinationView(viewModel: suggestedDestinationViewModel)
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}

struct SendDestinationView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        SendDestinationView(namespace: namespace, viewModel: SendDestinationViewModel(input: SendDestinationViewModelInputMock()))
    }
}
