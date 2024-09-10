//
//  SendDestinationCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class SendDestinationCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 88)
    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []

    let addressTextViewHeightModel: AddressTextViewHeightModel
    private weak var input: SendDestinationInput?
    private var inputSubscription: AnyCancellable?

    init(
        input: SendDestinationInput,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) {
        self.input = input
        self.addressTextViewHeightModel = addressTextViewHeightModel

        bind(input: input)
    }

    func bind(input: SendDestinationInput) {
        inputSubscription = Publishers
            .CombineLatest(input.destinationPublisher, input.additionalFieldPublisher)
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                viewModel.makeDestinationViewTypes(address: args.0.value, additionalField: args.1)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.destinationViewTypes, on: self, ownership: .weak)
    }

    private func makeDestinationViewTypes(address: String, additionalField: SendDestinationAdditionalField) -> [SendDestinationSummaryViewType] {
        var destinationViewTypes: [SendDestinationSummaryViewType] = []

        var addressCorners: UIRectCorner = .allCorners

        if case .filled(let type, let value, _) = additionalField {
            addressCorners = [.topLeft, .topRight]
            destinationViewTypes.append(.additionalField(type: type, value: value))
        }

        destinationViewTypes.insert(.address(address: address, corners: addressCorners), at: 0)

        return destinationViewTypes
    }
}
