//
//  SendAmountInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendAmountInteractor {
    var infoTextPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }
    var externalAmountPublisher: AnyPublisher<SendAmount?, Never> { get }

    func update(amount: Decimal?) -> SendAmount?
    func update(type: SendAmountCalculationType) -> SendAmount?
    func updateToMaxAmount() -> SendAmount?

    /// Use this method if have to updated from notification
    func externalUpdate(amount: Decimal?)
}

class CommonSendAmountInteractor {
    private let tokenItem: TokenItem
    private let maxAmount: Decimal

    private weak var input: SendAmountInput?
    private weak var output: SendAmountOutput?
    private let validator: SendAmountValidator
    private let amountModifier: SendAmountModifier?

    private var type: SendAmountCalculationType

    private var _cachedAmount: CurrentValueSubject<SendAmount?, Never>
    private var _error: CurrentValueSubject<String?, Never> = .init(nil)
    private var _isValid: CurrentValueSubject<Bool, Never> = .init(false)

    private var _externalAmount: PassthroughSubject<SendAmount?, Never> = .init()
    private var bag: Set<AnyCancellable> = []

    init(
        input: SendAmountInput,
        output: SendAmountOutput,
        tokenItem: TokenItem,
        maxAmount: Decimal,
        validator: SendAmountValidator,
        amountModifier: SendAmountModifier?,
        type: SendAmountCalculationType
    ) {
        self.input = input
        self.output = output
        self.tokenItem = tokenItem
        self.maxAmount = maxAmount
        self.validator = validator
        self.amountModifier = amountModifier
        self.type = type

        _cachedAmount = CurrentValueSubject(input.amount)

        bind()
    }

    private func bind() {
        _cachedAmount
            .withWeakCaptureOf(self)
            .sink { interactor, amount in
                interactor.validateAndUpdate(amount: amount)
            }
            .store(in: &bag)
    }

    private func validateAndUpdate(amount: SendAmount?) {
        guard let crypto = positiveCryptoAmount(for: amount) else { return }

        do {
            try validator.validate(amount: crypto)

            let amount = modifyIfNeeded(amount: amount)

            guard let crypto = positiveCryptoAmount(for: amount) else { return }

            try validator.validate(amount: crypto)
            update(amount: amount, isValid: true, error: .none)
        } catch {
            update(amount: .none, isValid: false, error: error)
        }
    }

    private func positiveCryptoAmount(for amount: SendAmount?) -> Decimal? {
        guard let crypto = amount?.crypto, crypto > 0 else {
            // Field is empty or zero
            update(amount: .none, isValid: false, error: .none)
            return nil
        }
        return crypto
    }

    private func update(amount: SendAmount?, isValid: Bool, error: Error?) {
        _error.send(error?.localizedDescription)
        _isValid.send(isValid)
        output?.amountDidChanged(amount: amount)
    }

    private func modifyIfNeeded(amount: SendAmount?) -> SendAmount? {
        guard let crypto = amountModifier?.modify(cryptoAmount: amount?.crypto) else {
            return amount
        }

        let fiat = convertToFiat(cryptoValue: crypto)
        return makeSendAmount(crypto: crypto, fiat: fiat)
    }

    private func makeSendAmount(crypto: Decimal?, fiat: Decimal?) -> SendAmount {
        switch type {
        case .crypto:
            return .init(type: .typical(crypto: crypto, fiat: fiat))
        case .fiat:
            return .init(type: .alternative(fiat: fiat, crypto: crypto))
        }
    }

    private func convertToCrypto(fiatValue: Decimal?) -> Decimal? {
        // If already have the converted the `crypto` amount associated with current `fiat` amount
        if input?.amount?.fiat == fiatValue {
            return input?.amount?.crypto
        }

        return SendAmountConverter().convertToCrypto(fiatValue, tokenItem: tokenItem)
    }

    private func convertToFiat(cryptoValue: Decimal?) -> Decimal? {
        // If already have the converted the `fiat` amount associated with current `crypto` amount
        if input?.amount?.crypto == cryptoValue {
            return input?.amount?.fiat
        }

        return SendAmountConverter().convertToFiat(cryptoValue, tokenItem: tokenItem)
    }
}

// MARK: - SendAmountInteractor

extension CommonSendAmountInteractor: SendAmountInteractor {
    var infoTextPublisher: AnyPublisher<SendAmountViewModel.BottomInfoTextType?, Never> {
        let info = amountModifier?.modifyingMessagePublisher ?? .just(output: nil)

        return Publishers.Merge(
            info.removeDuplicates().map { $0.map { .info($0) } },
            _error.removeDuplicates().map { $0.map { .error($0) } }
        )
        .eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        _isValid.eraseToAnyPublisher()
    }

    var externalAmountPublisher: AnyPublisher<SendAmount?, Never> {
        _externalAmount.eraseToAnyPublisher()
    }

    func update(amount: Decimal?) -> SendAmount? {
        guard let amount else {
            _cachedAmount.send(nil)
            return nil
        }

        let sendAmount: SendAmount = {
            switch type {
            case .crypto:
                let fiat = convertToFiat(cryptoValue: amount)
                return makeSendAmount(crypto: amount, fiat: fiat)
            case .fiat:
                let crypto = convertToCrypto(fiatValue: amount)
                return makeSendAmount(crypto: crypto, fiat: amount)
            }
        }()

        _cachedAmount.send(sendAmount)

        return sendAmount
    }

    func update(type: SendAmountCalculationType) -> SendAmount? {
        guard self.type != type else {
            return input?.amount
        }

        self.type = type
        let sendAmount = _cachedAmount.value?.toggle(type: type)
        validateAndUpdate(amount: sendAmount)
        return sendAmount
    }

    func updateToMaxAmount() -> SendAmount? {
        switch type {
        case .crypto:
            let fiat = convertToFiat(cryptoValue: maxAmount)
            let amount = SendAmount(type: .typical(crypto: maxAmount, fiat: fiat))
            _cachedAmount.send(amount)
            return amount
        case .fiat:
            let fiat = convertToFiat(cryptoValue: maxAmount)
            let amount = SendAmount(type: .alternative(fiat: fiat, crypto: maxAmount))
            _cachedAmount.send(amount)
            return amount
        }
    }

    func externalUpdate(amount: Decimal?) {
        let amount = update(amount: amount)
        _externalAmount.send(amount)
    }
}

enum SendAmountCalculationType {
    case crypto
    case fiat
}
