//
//  RadiantNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class RadiantNetworkService {
    let electrumProvider: ElectrumNetworkProvider

    init(electrumProvider: ElectrumNetworkProvider) {
        self.electrumProvider = electrumProvider
    }
}

extension RadiantNetworkService: HostProvider {
    var host: String {
        electrumProvider.host
    }
}

extension RadiantNetworkService {
    func getInfo(address: String) -> AnyPublisher<RadiantAddressInfo, Error> {
        let defferedScriptHash = Deferred {
            return Future { promise in
                let result = Result { try RadiantAddressUtils().prepareScriptHash(address: address) }
                promise(result)
            }
        }

        return defferedScriptHash
            .withWeakCaptureOf(self)
            .flatMap { service, value in
                service.electrumProvider
                    .getAddressInfo(identifier: .scriptHash(value))
            }
            .map { info in
                RadiantAddressInfo(balance: info.balance, outputs: info.outputs)
            }
            .eraseToAnyPublisher()
    }

    func estimatedFee() -> AnyPublisher<BitcoinFee, Error> {
        electrumProvider
            .estimateFee()
            .map { sourceFee in
                let targetFee = max(sourceFee, Constants.recommendedFeePer1000Bytes)

                let minimal = targetFee
                let normal = targetFee * Constants.normalFeeMultiplier
                let priority = targetFee * Constants.priorityFeeMultiplier

                return BitcoinFee(
                    minimalSatoshiPerByte: minimal,
                    normalSatoshiPerByte: normal,
                    prioritySatoshiPerByte: priority
                )
            }
            .eraseToAnyPublisher()
    }

    func sendTransaction(data: Data) -> AnyPublisher<String, Error> {
        electrumProvider
            .send(transactionHex: data.hexString)
    }
}

extension RadiantNetworkService {
    enum Constants {
        /*
          This minimal rate fee for successful transaction from constant
          -  Relying on answers from blockchain developers and costs from the official application (Electron-Radiant).
          - 10000 satoshi per byte or 0.1 RXD per KB.
         */

        static let recommendedFeePer1000Bytes: Decimal = .init(stringValue: "0.1")!
        static let normalFeeMultiplier: Decimal = .init(stringValue: "1.5")!
        static let priorityFeeMultiplier: Decimal = .init(stringValue: "2")!
    }
}
