//
//  EthereumFeeParameters.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BigInt

// MARK: - EthereumFeeParameters

public protocol EthereumFeeParameters where Self: FeeParameters {
    var parametersType: EthereumFeeParametersType { get }

    func changingGasLimit(to value: BigUInt) -> Self
    func calculateFee(decimalValue: Decimal) -> Decimal
}

public extension EthereumFeeParameters {
    var gasLimit: BigUInt {
        switch parametersType {
        case .eip1559(let params):
            return params.gasLimit
        case .legacy(let params):
            return params.gasLimit
        }
    }
}

// MARK: - EthereumFeeParametersType

public enum EthereumFeeParametersType {
    case legacy(EthereumLegacyFeeParameters)
    case eip1559(EthereumEIP1559FeeParameters)
}

// MARK: - EthereumLegacyFeeParameters

public struct EthereumLegacyFeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    public let gasPrice: BigUInt

    public init(gasLimit: BigUInt, gasPrice: BigUInt) {
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
    }
}

extension EthereumLegacyFeeParameters: EthereumFeeParameters {
    public var parametersType: EthereumFeeParametersType {
        .legacy(self)
    }

    public func calculateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * gasPrice
        // TODO: Fix integer overflow. Think about BigInt
        // https://tangem.atlassian.net/browse/IOS-4268
        // https://tangem.atlassian.net/browse/IOS-5119
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        return feeValue / decimalValue
    }

    public func changingGasLimit(to value: BigUInt) -> EthereumLegacyFeeParameters {
        let feeParameters = EthereumLegacyFeeParameters(
            gasLimit: value,
            gasPrice: gasPrice
        )

        return feeParameters
    }
}

// MARK: - EthereumEIP1559FeeParameters

public struct EthereumEIP1559FeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    /// Maximum fee which will be spend. Should include `priorityFee` in itself
    public let maxFeePerGas: BigUInt
    /// The part of `maxFeePerGas` which will be sent a mainer like a tips
    public let priorityFee: BigUInt

    public init(gasLimit: BigUInt, baseFee: BigUInt, priorityFee: BigUInt) {
        self.gasLimit = gasLimit
        self.maxFeePerGas = baseFee + priorityFee
        self.priorityFee = priorityFee
    }

    public init(gasLimit: BigUInt, maxFeePerGas: BigUInt, priorityFee: BigUInt) {
        self.gasLimit = gasLimit
        self.maxFeePerGas = maxFeePerGas
        self.priorityFee = priorityFee
    }
}

extension EthereumEIP1559FeeParameters: EthereumFeeParameters {
    public var parametersType: EthereumFeeParametersType {
        .eip1559(self)
    }

    public func calculateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * maxFeePerGas
        // TODO: Fix integer overflow. Think about BigInt
        // https://tangem.atlassian.net/browse/IOS-4268
        // https://tangem.atlassian.net/browse/IOS-5119
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        return feeValue / decimalValue
    }

    public func changingGasLimit(to value: BigUInt) -> EthereumEIP1559FeeParameters {
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: value,
            maxFeePerGas: maxFeePerGas,
            priorityFee: priorityFee
        )

        return feeParameters
    }
}
