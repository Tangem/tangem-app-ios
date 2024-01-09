//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendFinishViewModelInput: AnyObject {
    var amountText: String { get }
    var destinationText: String? { get }
    var feeText: String { get }
    var transactionTime: Date? { get }
    var transactionURL: URL? { get }
}

class SendFinishViewModel: ObservableObject {
    let amountText: String
    let destinationText: String
    let feeText: String
    let transactionTime: String

    weak var router: SendFinishRoutable?

    private let transactionURL: URL

    init?(input: SendFinishViewModelInput) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        guard
            let destinationText = input.destinationText,
            let transactionTime = input.transactionTime,
            let transactionURL = input.transactionURL

        else {
            return nil
        }

        amountText = input.amountText
        self.destinationText = destinationText
        feeText = input.feeText
        self.transactionTime = formatter.string(from: transactionTime)
        self.transactionURL = transactionURL
    }

    func explore() {
        router?.explore(url: transactionURL)
    }

    func share() {
        router?.share(url: transactionURL)
    }

    func close() {
        router?.dismiss()
    }
}
