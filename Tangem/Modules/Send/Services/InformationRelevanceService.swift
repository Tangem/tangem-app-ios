//
//  InformationRelevanceService.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol InformationRelevanceService {
    var isActual: Bool { get }

    func informationDidUpdated()
    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, Error>
}

class CommonInformationRelevanceService {
    private let sendFeeInteractor: SendFeeInteractor

    private var lastUpdateStartTime = Date()
    private let informationValidityInterval: TimeInterval = 60
    private var bag: Set<AnyCancellable> = []

    init(sendFeeInteractor: SendFeeInteractor) {
        self.sendFeeInteractor = sendFeeInteractor

        bind()
    }

    private func bind() {
        sendFeeInteractor
            .selectedFeePublisher
            .withWeakCaptureOf(self)
            .sink { service, _ in
                service.informationDidUpdated()
            }
            .store(in: &bag)
    }

    private func compare(selected: SendFee?, fees: [SendFee]) -> InformationRelevanceServiceUpdateResult {
        let oldFeeValue = selected?.value.value?.amount.value
        let newFee = fees.first(where: { $0.option == selected?.option })

        guard let oldFeeValue,
              let newFee,
              let newFeeValue = newFee.value.value?.amount.value,
              newFeeValue > oldFeeValue else {
            return .ok
        }

        sendFeeInteractor.update(selectedFee: newFee)
        return .feeWasIncreased
    }
}

// MARK: - InformationRelevanceService

extension CommonInformationRelevanceService: InformationRelevanceService {
    var isActual: Bool {
        Date().timeIntervalSince(lastUpdateStartTime) < informationValidityInterval
    }

    func informationDidUpdated() {
        lastUpdateStartTime = Date()
    }

    func updateInformation() -> AnyPublisher<InformationRelevanceServiceUpdateResult, any Error> {
        defer {
            sendFeeInteractor.updateFees()
        }

        let oldFee = sendFeeInteractor.selectedFee

        // Catch the subscribtions
        return sendFeeInteractor
            .feesPublisher
            // Skip the old values
            .dropFirst()
            .withWeakCaptureOf(self)
            .tryMap { service, fees in
                if let error = fees.first(where: { $0.value.error != nil })?.value.error {
                    throw error
                }

                service.informationDidUpdated()
                return service.compare(selected: oldFee, fees: fees)
            }
            .eraseToAnyPublisher()
    }
}

enum InformationRelevanceServiceUpdateResult {
    case ok
    case feeWasIncreased
}
