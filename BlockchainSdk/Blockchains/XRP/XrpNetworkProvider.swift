//
//  XRPNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class XRPNetworkProvider: XRPNetworkServiceType, HostProvider {
    var host: String {
        node.url.absoluteString
    }

    private let node: NodeInfo
    private let provider: NetworkProvider<XRPTarget>

    init(node: NodeInfo, configuration: NetworkProviderConfiguration) {
        self.node = node
        provider = NetworkProvider<XRPTarget>(configuration: configuration)
    }

    func getFee() -> AnyPublisher<XRPFeeResponse, Error> {
        return request(.fee)
            .tryMap { xrpResponse -> XRPFeeResponse in
                guard let minFee = xrpResponse.result?.drops?.minimum_fee,
                      let normalFee = xrpResponse.result?.drops?.open_ledger_fee,
                      let maxFee = xrpResponse.result?.drops?.median_fee,
                      let minFeeDecimal = Decimal(string: minFee),
                      let normalFeeDecimal = Decimal(string: normalFee),
                      let maxFeeDecimal = Decimal(string: maxFee) else {
                    throw WalletError.failedToGetFee
                }

                return XRPFeeResponse(min: minFeeDecimal, normal: normalFeeDecimal, max: maxFeeDecimal)
            }
            .eraseToAnyPublisher()
    }

    func send(blob: String) -> AnyPublisher<String, Error> {
        return request(.submit(tx: blob))
            .tryMap { xrpResponse -> String in
                guard let code = xrpResponse.result?.engine_result_code else {
                    throw WalletError.failedToSendTx
                }

                if code != 0 {
                    let message = xrpResponse.result?.engine_result_message ?? WalletError.failedToSendTx.localizedDescription
                    if message != "Held until escalated fee drops." { // TODO: find the error code
                        throw message
                    }
                }

                guard let hash = xrpResponse.result?.tx_json?.hash else {
                    throw WalletError.failedToSendTx
                }

                return hash
            }
            .eraseToAnyPublisher()
    }

    func getUnconfirmed(account: String) -> AnyPublisher<Decimal, Error> {
        return request(.unconfirmed(account: account))
            .tryMap { xrpResponse -> Decimal in
                try xrpResponse.assertAccountCreated()

                guard let unconfirmedBalanceString = xrpResponse.result?.account_data?.balance,
                      let unconfirmedBalance = Decimal(unconfirmedBalanceString) else {
                    throw XRPError.failedLoadUnconfirmed
                }

                return unconfirmedBalance
            }
            .eraseToAnyPublisher()
    }

    func getReserve() -> AnyPublisher<Decimal, Error> {
        return request(.reserve)
            .tryMap { xrpResponse -> Decimal in
                try xrpResponse.assertAccountCreated()

                guard let reserveBase = xrpResponse.result?.state?.validated_ledger?.reserve_base else {
                    throw XRPError.failedLoadReserve
                }

                return Decimal(reserveBase)
            }
            .eraseToAnyPublisher()
    }

    func getAccountInfo(account: String) -> AnyPublisher<(balance: Decimal, sequence: Int), Error> {
        return request(.accountInfo(account: account))
            .tryMap { xrpResponse in
                try xrpResponse.assertAccountCreated()

                guard let accountResponse = xrpResponse.result?.account_data,
                      let balanceString = accountResponse.balance,
                      let sequence = accountResponse.sequence,
                      let balance = Decimal(balanceString) else {
                    throw XRPError.failedLoadInfo
                }

                return (balance: balance, sequence: sequence)
            }
            .eraseToAnyPublisher()
    }

    func getInfo(account: String) -> AnyPublisher<XrpInfoResponse, Error> {
        return Publishers.Zip3(
            getUnconfirmed(account: account),
            getReserve(),
            getAccountInfo(account: account)
        )
        .map { unconfirmed, reserve, info -> XrpInfoResponse in
            return XrpInfoResponse(
                balance: info.balance,
                sequence: info.sequence,
                unconfirmedBalance: unconfirmed,
                reserve: reserve
            )
        }
        .eraseToAnyPublisher()
    }

    func checkAccountCreated(account: String) -> AnyPublisher<Bool, Error> {
        return request(.accountInfo(account: account))
            .map { xrpResponse -> Bool in
                do {
                    try xrpResponse.assertAccountCreated()
                    return true
                } catch {
                    return false
                }
            }
            .eraseToAnyPublisher()
            .eraseError()
    }

    private func request(_ target: XRPTarget.XRPTargetType) -> AnyPublisher<XrpResponse, MoyaError> {
        provider
            .requestPublisher(XRPTarget(node: node, target: target))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(XrpResponse.self)
    }
}
