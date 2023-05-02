//
//  SaltPayRegistrator.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import web3swift
import Combine

class SaltPayRegistrator {
    @Published public private(set) var state: State = .needPin
    @Published public private(set) var error: AlertBinder? = nil
    @Published public private(set) var isBusy: Bool = false

    var canClaim: Bool {
        guard let claimableAmount else {
            return false
        }

        return !claimableAmount.isZero
    }

    var claimableAmountDescription: String {
        claimableAmount?.string(with: 8) ?? ""
    }

    var kycURL: URL {
        let kycProvider = keysManager.saltPay.kycProvider

        var urlComponents = URLComponents(string: kycProvider.baseUrl)!

        var queryItems = [URLQueryItem]()
        queryItems.append(.init(name: kycProvider.externalIdParameterKey, value: kycRefId))
        queryItems.append(.init(name: kycProvider.sidParameterKey, value: kycProvider.sidValue))

        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }

    var needsKYC: Bool {
        registrationState?.kycStatus != .approved
    }

    var kycDoneURL: String {
        "https://success.tangem.com"
    }

    @Injected(\.keysManager) private var keysManager: KeysManager

    private let api: PaymentologyApiService = CommonPaymentologyApiService()
    private let gnosis: GnosisRegistrator
    private let cardId: String
    private let cardPublicKey: Data
    private let walletPublicKey: Data
    private var bag: Set<AnyCancellable> = .init()
    private var pin: String?
    private var hasGas: Bool?
    private var registrationState: RegistrationResponse.Item?
    private var registrationTask: RegistrationTask?
    private var accessCode: String?
    private var claimableAmount: Amount?

    private let approvalValue: Decimal = .greatestFiniteMagnitude
    private let spendLimitValue: Decimal = 100
    private let sdk: TangemSdk

    private var kycRefId: String {
        UserWalletId(with: walletPublicKey).stringValue
    }

    init(cardId: String, cardPublicKey: Data, walletPublicKey: Data, gnosis: GnosisRegistrator) {
        self.gnosis = gnosis
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
        self.walletPublicKey = walletPublicKey
        sdk = SaltPayTangemSdkFactory(isAccessCodeSet: false).makeTangemSdk()
    }

    func setAccessCode(_ accessCode: String) {
        self.accessCode = accessCode
    }

    func setPin(_ pin: String) -> Bool {
        do {
            try assertPinValid(pin)
            self.pin = pin
            updateState()
            return true
        } catch {
            self.error = (error as! SaltPayRegistratorError).alertBinder
            return false
        }
    }

    func update(_ completion: ((State) -> Void)? = nil) {
        isBusy = true

        updatePublisher()
            .sink { [weak self] completionResult in
                guard let self = self else { return }

                if case .failure(let error) = completionResult {
                    self.error = error.alertBinder
                }

                self.isBusy = false
                completion?(self.state)
            } receiveValue: { _ in }
            .store(in: &bag)
    }

    func claim(_ completion: @escaping (Result<Void, Error>) -> Void) {
        isBusy = true

        guard let claimableAmount = claimableAmount else {
            completion(.failure(SaltPayRegistratorError.missingClaimableAmount))
            return
        }

        gnosis.checkHasGas()
            .flatMap { [weak self] _ -> AnyPublisher<CompiledEthereumTransaction, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.gnosis.makeClaimTx(value: claimableAmount)
            }
            .flatMap { [weak self] tx -> AnyPublisher<SignedEthereumTransaction, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.sdk.startSessionPublisher(with: SignHashCommand(hash: tx.hash, walletPublicKey: self.walletPublicKey), accessCode: self.accessCode)
                    .map { signResponse -> SignedEthereumTransaction in
                        .init(compiledTransaction: tx, signature: signResponse.signature)
                    }
                    .eraseError()
            }
            .flatMap { [weak self] tx -> AnyPublisher<Void, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.gnosis.sendTransactions([tx])
            }
            .receiveCompletion { [weak self] completionResult in
                switch completionResult {
                case .failure(let error):
                    if !error.toTangemSdkError().isUserCancelled {
                        self?.error = error.alertBinder
                    }
                    completion(.failure(error))
                case .finished:
                    self?.claimableAmount = nil
                    self?.updateState()
                    completion(.success(()))
                }

                self?.isBusy = false
            }
            .store(in: &bag)
    }

    func updatePublisher() -> AnyPublisher<Void, Error> {
        checkRegistration()
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.checkGasIfNeeded()
            }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.checkCanClaimIfNeeded()
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.updateState()
            })
            .eraseToAnyPublisher()
    }

    func register() {
        isBusy = true

        checkGasIfNeeded()
            .flatMap { [weak self] _ -> AnyPublisher<AttestationResponse, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.api.requestAttestationChallenge(for: self.cardId, publicKey: self.cardPublicKey)
            }
            .flatMap { [weak self] attestationResponse -> AnyPublisher<RegistrationTask.Response, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                let task = RegistrationTask(
                    gnosis: self.gnosis,
                    challenge: attestationResponse.challenge,
                    walletPublicKey: self.walletPublicKey,
                    approvalValue: self.approvalValue,
                    spendLimitValue: self.spendLimitValue
                )

                self.registrationTask = task

                return self.sdk.startSessionPublisher(
                    with: task,
                    cardId: self.cardId,
                    initialMessage: nil,
                    accessCode: self.accessCode
                )
                .eraseToAnyPublisher()
                .eraseError()
            }
            .flatMap { [gnosis] response -> AnyPublisher<RegistrationTask.RegistrationTaskResponse, Error> in
//                return Just(response) // TODO: remove, test only
//                    .delay(for: .seconds(5), scheduler: DispatchQueue.global())
//                    .setFailureType(to: Error.self)
//                    .eraseToAnyPublisher()
                return gnosis.sendTransactions(response.signedTransactions)
                    .map { result -> RegistrationTask.RegistrationTaskResponse in
                        return response
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] response -> AnyPublisher<RegisterWalletResponse, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                guard let pin = self.pin else {
                    return .anyFail(error: SaltPayRegistratorError.needPin)
                }

                let cardSalt = response.attestResponse.publicKeySalt ?? Data()
                let cardSignature = response.attestResponse.cardSignature ?? Data()

                let request = ReqisterWalletRequest(
                    cardId: self.cardId,
                    publicKey: self.cardPublicKey,
                    walletPublicKey: self.walletPublicKey,
                    walletSalt: response.attestResponse.salt,
                    walletSignature: response.attestResponse.walletSignature,
                    cardSalt: cardSalt,
                    cardSignature: cardSignature,
                    pin: pin
                )

                return self.api.registerWallet(request: request)
                    // .replaceError(with: RegisterWalletResponse(error: nil, errorCode: nil, success: true)) //TODO: remove
                    // .setFailureType(to: Error.self) //TODO: remove
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else { return .anyFail(error: SaltPayRegistratorError.empty) }

                return self.checkRegistration().eraseToAnyPublisher()
            }
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    if !error.toTangemSdkError().isUserCancelled {
                        self?.error = error.alertBinder
                    }
                }

                self?.isBusy = false
            } receiveValue: {
                Analytics.log(.pinCodeSet)
            }
            .store(in: &bag)
    }

    private func updateState() {
        guard let registrationState = registrationState else { return }

        var newState: State = state

        if registrationState.active == true {
            if canClaim {
                newState = .claim // active is true, can claim, go to claim screen
            } else {
                newState = .finished // active is true, go to success screen
            }
        } else if registrationState.pinSet != true {
            if pin == nil {
                newState = .needPin // pinset is false, go to pin screen
            } else {
                newState = .registration // has enterd pin, go to regstration screen
            }
        } else {
            if let status = registrationState.kycStatus {
                switch status {
                case .notStarted, .started, .unknown:
                    newState = .kycStart
                case .rejected, .correctionRequested:
                    newState = .kycRetry
                case .waitingForApproval:
                    newState = .kycWaiting
                case .approved: // Handled by registrationState.active == true ?
                    if canClaim {
                        newState = .claim // active is true, can claim, go to claim screen
                    } else {
                        newState = .finished // active is true, go to success screen
                    }
                }
            } else {
                newState = .kycStart
            }
        }

        if newState != state {
            state = newState
        }
    }

    public func registerKYC() {
        let request = RegisterKYCRequest(
            cardId: cardId,
            publicKey: cardPublicKey,
            kycProvider: "UTORG",
            kycRefId: kycRefId
        )

        state = .kycWaiting

        api.registerKYC(request: request)
            .map { _ in }
            .receiveCompletion { _ in }
            .store(in: &bag)
    }

    private func checkGasIfNeeded() -> AnyPublisher<Void, Error> {
        guard state == .registration || state == .needPin else {
            return .justWithError(output: ())
        }

        return gnosis.checkHasGas()
            .handleEvents(receiveOutput: { [weak self] response in
                self?.hasGas = response
                self?.updateState()
            })
            .mapError { error in
                AppLog.shared.error(error)
                return SaltPayRegistratorError.blockchainError
            }
            .tryMap { hasGas in
                if !hasGas {
                    Analytics.log(.notEnoughGasError)
                    throw SaltPayRegistratorError.noGas
                }
            }
            .eraseToAnyPublisher()
    }

    private func checkCanClaimIfNeeded() -> AnyPublisher<Void, Error> {
        guard !canClaim else {
            return .justWithError(output: ())
        }

        return gnosis.getClaimableAmount()
            .handleEvents(receiveOutput: { [weak self] claimable in
                self?.claimableAmount = claimable
                self?.updateState()
            })
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func checkRegistration() -> AnyPublisher<Void, Error> {
        api.checkRegistration(for: cardId, publicKey: cardPublicKey)
            .handleEvents(receiveOutput: { [weak self] response in
                self?.registrationState = response
                self?.updateState()
            })
            .tryMap { response in
                guard response.passed == true else { // passed is false, show error
                    Analytics.log(.cardNotPassedError)
                    throw SaltPayRegistratorError.cardNotPassed
                }

                if response.disabledByAdmin == true { // disabledByAdmin is true, show error
                    throw SaltPayRegistratorError.cardDisabled
                }
            }
            .eraseToAnyPublisher()
    }

    private func assertPinValid(_ pin: String) throws {
        let array = Array(pin)

        if array.count < Constants.pinLength {
            throw SaltPayRegistratorError.weakPin
        }

        for char in array[1...] {
            if array[0] != char {
                return
            }
        }

        throw SaltPayRegistratorError.weakPin
    }
}

extension SaltPayRegistrator {
    enum Constants {
        static let pinLength: Int = 4
    }
}

extension SaltPayRegistrator {
    enum State: Equatable {
        case needPin
        case registration
        case kycStart
        case kycRetry
        case kycWaiting
        case claim
        case finished
    }
}
