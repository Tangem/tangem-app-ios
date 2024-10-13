//
//  HederaTransactionIdConverter.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaTransactionIdConverter {
    /// Conversion from `0.0.3573746@1714011910.250372802` to `0.0.3573746-1714011910-250372802`.
    func convertFromConsensusToMirror(_ transactionId: String) throws -> String {
        let firstStageParts = transactionId.components(separatedBy: Constants.consensusTimestampSeparator)

        guard firstStageParts.count == 2 else {
            throw ConversionError.conversionFromConsensusToMirrorFailed(transactionId: transactionId)
        }

        let secondStageParts = firstStageParts[1].components(separatedBy: Constants.consensusNanosecondsSeparator)

        guard secondStageParts.count == 2 else {
            throw ConversionError.conversionFromConsensusToMirrorFailed(transactionId: transactionId)
        }

        return [
            firstStageParts[0],
            secondStageParts[0],
            secondStageParts[1],
        ].joined(separator: Constants.mirrorSeparator)
    }

    /// Conversion from `0.0.3573746-1714011910-250372802` to `0.0.3573746@1714011910.250372802`
    func convertFromMirrorToConsensus(_ transactionId: String) throws -> String {
        let firstStageParts = transactionId.components(separatedBy: Constants.mirrorSeparator)

        guard firstStageParts.count == 3 else {
            throw ConversionError.conversionFromMirrorToConsensusFailed(transactionId: transactionId)
        }

        let intermediateResult = [
            firstStageParts[1],
            firstStageParts[2],
        ].joined(separator: Constants.consensusNanosecondsSeparator)

        return [
            String(firstStageParts[0]),
            intermediateResult,
        ].joined(separator: Constants.consensusTimestampSeparator)
    }
}

// MARK: - Auxiliary types

extension HederaTransactionIdConverter {
    enum ConversionError: Error {
        case conversionFromConsensusToMirrorFailed(transactionId: String)
        case conversionFromMirrorToConsensusFailed(transactionId: String)
    }
}

// MARK: - Constants

private extension HederaTransactionIdConverter {
    enum Constants {
        static let consensusTimestampSeparator = "@"
        static let consensusNanosecondsSeparator = "."
        static let mirrorSeparator = "-"
    }
}
