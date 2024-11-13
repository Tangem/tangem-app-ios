//
//  QRCodeParser.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// Supports https://github.com/bitcoin/bips/blob/master/bip-0020.mediawiki and https://eips.ethereum.org/EIPS/eip-681 (partially).
struct QRCodeParser {
    let amountType: Amount.AmountType
    let blockchain: Blockchain
    let decimalCount: Int

    func parse(_ qrCode: String) -> Result? {
        let qrCodeWithoutSchemaPrefix = stripSchemaPrefix(from: qrCode)
        let scanner = Scanner(string: qrCodeWithoutSchemaPrefix)

        // A poor man's ERC-681 parser: we want to extract only the destination address, and we don't care
        // about other parts of the ERC-681 payload string like `chain_id` and/or `function_name`.
        //
        // We're extracting the destination address by parsing the given string until we meet
        // any of the possible string delimiters (from `Constants.addressDelimiterCharacters`).
        let address = scanner.scanUpToCharacters(from: Constants.addressDelimiterCharacters) ?? qrCodeWithoutSchemaPrefix
        var result = Result(destination: address)

        let parameters = extractParameters(from: qrCodeWithoutSchemaPrefix)
        for parameter in parameters {
            guard
                let parameterName = ParameterName(rawValue: parameter.name),
                let parameterValue = parameter.value?.nilIfEmpty
            else {
                continue
            }

            switch parameterName {
            case .amount:
                // According to BIP-0021, the value is specified in decimals. No conversion needed
                if let decimalValue = parseDecimal(parameterValue) {
                    result.amount = makeAmount(with: decimalValue)
                }
            case .message, .memo:
                result.memo = parameterValue.removingPercentEncoding
            case .address:
                // Overrides destination address for token transfers (`address` parameter from ERC-681)
                //
                // `address` parameter is used only if the contract address, encoded in the QR,
                // matches the contract address of the token from `amountType` property.
                // Otherwise, the scanned string is likely malformed, and we stop the entire parsing routine
                guard
                    case .token(let token) = amountType,
                    token.contractAddress.caseInsensitiveCompare(result.destination) == .orderedSame
                else {
                    return nil
                }

                result.destination = parameterValue
            case .value, .uint256:
                // According to ERC-681, the value is specified in the atomic unit (i.e. wei). Converting it to decimals
                if let valueInSmallestDenomination = parseDecimal(parameterValue) {
                    let value = valueInSmallestDenomination / pow(Decimal(10), decimalCount)
                    result.amount = makeAmount(with: value)
                }
            }
        }

        return result
    }

    private func stripSchemaPrefix(from qrCode: String) -> String {
        var result = qrCode

        // The most specific (i.e. the most lengthy) prefixes always come first
        let qrPrefixes = blockchain
            .qrPrefixes
            .sorted { $0.count > $1.count }

        for qrPrefix in qrPrefixes {
            // Sometimes there are quite weird prefixes like "Address=bitcoin:" or "destination=ethereum:";
            // therefore we have to cut out an entire prefix, including all garbage in front
            let components = qrCode.components(separatedBy: qrPrefix)
            if components.count > 1 {
                result = components.dropFirst().joined()
                break
            }
        }

        return result
    }

    private func extractParameters(from qrCode: String) -> [URLQueryItem] {
        let components = qrCode.split(separator: "?")

        guard
            components.count > 1,
            let rawParametersString = components.last
        else {
            return []
        }

        return rawParametersString
            .split(separator: "&")
            .map { String($0) }
            .map { $0.split(separator: "=") }
            .filter { $0.count == 2 }
            .map { parameter in
                let name = String(parameter[0]).lowercased()
                let value = String(parameter[1])
                return URLQueryItem(name: name, value: value)
            }
    }

    private func parseDecimal(_ stringValue: String) -> Decimal? {
        let decimalSeparator = Locale.posixEnUS.decimalSeparator ?? "."
        let normalizedStringValue = stringValue.replacingOccurrences(of: ",", with: decimalSeparator)

        // If the normalized string contains more than one separators (i.e. it can be divided into 3 or more parts),
        // like '1,234,567.89' or '1.234.567,89' - it violates both BIP-0021 and ERC-681 and can't be parsed reliably.
        // In this case, we consider the given string to be malformed, and we stop the decimal number parsing routine
        guard
            normalizedStringValue.split(separator: decimalSeparator.first!).count < 3,
            let value = Decimal(stringValue: normalizedStringValue)
        else {
            return nil
        }

        return value
    }

    private func makeAmount(with value: Decimal) -> Amount {
        return Amount(with: blockchain, type: amountType, value: value)
    }
}

// MARK: - Auxiliary types

extension QRCodeParser {
    struct Result {
        var destination: String
        var amount: Amount?
        var memo: String?
    }
}

// MARK: - Constants

private extension QRCodeParser {
    enum Constants {
        /// See https://eips.ethereum.org/EIPS/eip-681 for details.
        static let addressDelimiterCharacters: CharacterSet = [
            "@",
            "/",
            "?",
        ]
    }

    /// We don't care about other params from ERC-681, like `gasLimit`, `gasPrice` and so on.
    enum ParameterName: String, RawRepresentable {
        /// From BIP-0021, the value MUST be specified in decimal BTC.
        case amount
        /// From BIP-0021.
        case message
        case memo
        /// From ERC-681, the destination for token transfers.
        case address
        /// From ERC-681, the amount for Ethereum transfers.
        /// The value is specified in the Ethereum atomic unit (i.e. wei).
        /// The use of scientific notation is strongly encouraged.
        case value
        /// From ERC-681, the amount for token transfers.
        /// The value is specified in the token atomic unit.
        case uint256
    }
}
