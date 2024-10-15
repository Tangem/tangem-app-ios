//
//  VisaTokenInfoLoader.swift
//  TangemVisa
//
//  Created by Andrew Son on 17/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct VisaTokenInfoLoader {
    private let isTestnet: Bool
    private let evmSmartContractInteractor: EVMSmartContractInteractor
    private let logger: InternalLogger

    init(isTestnet: Bool, evmSmartContractInteractor: EVMSmartContractInteractor, logger: InternalLogger) {
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
        self.logger = logger
    }

    func loadTokenInfo(for paymentAccount: String) async throws -> Token {
        let contractAddress = try await loadContractAddress(for: paymentAccount)

        async let name = try loadText(for: contractAddress, requestType: .name)
        async let symbol = try loadText(for: contractAddress, requestType: .symbol)
        async let decimalsCount = try loadDecimalsCount(contractAddress: contractAddress)

        return try await .init(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalsCount,
            id: VisaUtilities(isTestnet: isTestnet).tokenId
        )
    }

    private func loadContractAddress(for paymentAccount: String) async throws -> String {
        let contractAddressRequest = VisaSmartContractRequest(contractAddress: paymentAccount, method: GetTokenInfoMethod(infoType: .contractAddress))

        do {
            let contractAddressResponse = try await evmSmartContractInteractor.ethCall(request: contractAddressRequest).async()
            let contractAddress = try AddressParser(isTestnet: isTestnet).parseAddressResponse(contractAddressResponse)
            log("Token contract address loaded and parsed. \n\(contractAddress)")
            return contractAddress
        } catch {
            log("Failed to load token contract address. Error: \(error)")
            throw Errors.failedToLoadInfo(method: .contractAddress)
        }
    }

    private func loadDecimalsCount(contractAddress: String) async throws -> Int {
        let request = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: .decimals))
        let response = try await evmSmartContractInteractor.ethCall(request: request).async()

        guard let decimals = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) else {
            throw Errors.failedToLoadInfo(method: .decimals)
        }

        return decimals.decimalNumber.intValue
    }

    private func loadText(for contractAddress: String, requestType: GetTokenInfoMethod.InfoType) async throws -> String {
        let request = VisaSmartContractRequest(contractAddress: contractAddress, method: GetTokenInfoMethod(infoType: requestType))
        let response = try await evmSmartContractInteractor.ethCall(request: request).async()
        let textData = Data(hexString: response)

        guard let text = String(data: textData, encoding: .utf8) else {
            throw Errors.failedToLoadInfo(method: requestType)
        }

        return trimSpacesAndNullCharacter(text)
    }

    private func trimSpacesAndNullCharacter(_ string: String) -> String {
        // We need to remove all null characters before usage.
        // For some reason, the smart contract sends strings cluttered with null characters.
        string.trimmingCharacters(in: .whitespacesAndNewlines.union(["\0"]))
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .tokenInfoLoader, message())
    }
}

extension VisaTokenInfoLoader {
    enum Errors: LocalizedError {
        case failedToLoadInfo(method: GetTokenInfoMethod.InfoType)

        var errorDescription: String? {
            switch self {
            case .failedToLoadInfo(let method):
                return "Failed method: \(method)"
            }
        }
    }
}
