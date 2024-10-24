//
//  NEARNetworkResult.TransactionStatus.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct AnyCodable.AnyDecodable

extension NEARNetworkResult {
    // There are many more fields in this response, but we only
    // care about the hash and status of the transaction.
    struct TransactionStatus: Decodable {
        struct TransactionOutcome: Decodable {
            /// Hash of the transaction.
            let id: String
        }

        // API specs don't list all possible transaction statuses, but it's likely that there are
        // other statuses except 'success' and 'failure' - like 'pending' or something like that.
        enum Status: Decodable {
            private enum CodingKeys: String, CodingKey {
                case success = "SuccessValue"
                case failure = "Failure"
            }

            case success
            case failure(AnyDecodable?)
            case other

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                if container.contains(.success) {
                    self = .success
                } else if container.contains(.failure) {
                    self = .failure(try? container.decodeIfPresent(forKey: .failure))
                } else {
                    self = .other
                }
            }
        }

        let transactionOutcome: TransactionOutcome
        let status: Status
    }
}
