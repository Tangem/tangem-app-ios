//
//  BlockBookTarget.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct BlockBookTarget: TargetType {
    let request: Request
    let config: BlockBookConfig
    let blockchain: Blockchain

    var baseURL: URL {
        switch request {
        case .fees, .sendNode:
            return URL(string: config.node(for: blockchain).rpcNode)!
        default:
            return URL(string: config.node(for: blockchain).restNode)!
        }
    }

    var path: String {
        let basePath = config.path(for: request)

        switch request {
        case .address(let address, _):
            return basePath + "/address/\(address)"
        case .sendBlockBook:
            return basePath + "/sendtx/"
        case .txDetails(let txHash):
            return basePath + "/tx/\(txHash)"
        case .utxo(let address):
            return basePath + "/utxo/\(address)"
        case .fees, .sendNode:
            return basePath
        case .getFees(let confirmationBlocks):
            return basePath + "/estimatefee/\(confirmationBlocks)"
        }
    }

    var method: Moya.Method {
        switch request {
        case .address, .utxo, .getFees:
            return .get
        case .sendBlockBook, .sendNode, .txDetails, .fees:
            return .post
        }
    }

    var task: Moya.Task {
        switch request {
        case .txDetails, .utxo, .getFees:
            return .requestPlain
        case .sendBlockBook(let tx):
            return .requestData(tx)
        case .sendNode(let request):
            return .requestJSONEncodable(request)
        case .fees(let request):
            return .requestJSONEncodable(request)
        case .address(_, let parameters):
            let parameters = try? parameters.asDictionary()
            return .requestParameters(parameters: parameters ?? [:], encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": contentType]

        // TODO: - if / let
        if let name = config.apiKeyHeaderName, let value = config.apiKeyHeaderValue {
            headers[name] = value
        }

        return headers
    }

    private var contentType: String {
        switch request {
        case .sendBlockBook:
            return "text/plain; charset=utf-8"
        default:
            return "application/json"
        }
    }
}

extension BlockBookTarget {
    enum Request {
        case address(address: String, parameters: AddressRequestParameters)
        case sendBlockBook(tx: Data)
        case sendNode(_ request: NodeRequest<String>)
        case txDetails(txHash: String)
        case utxo(address: String)
        case fees(_ request: NodeRequest<Int>)

        /*
         Use any method getFees request. Used for blockchains:
            - CloreAI
         */
        case getFees(confirmationBlocks: Int)
    }

    struct AddressRequestParameters: Encodable {
        /// Specifies page of returned transactions, starting from 1.
        /// If out of range, Blockbook returns the closest possible page.
        let page: Int?
        /// The number of transactions returned by call (default and maximum 1000)
        let pageSize: Int?
        let details: [Details]
        let filterType: FilterType?

        init(
            page: Int? = nil,
            pageSize: Int? = nil,
            details: [BlockBookTarget.AddressRequestParameters.Details],
            filterType: FilterType? = nil
        ) {
            self.page = page
            self.pageSize = pageSize
            self.details = details
            self.filterType = filterType
        }

        enum Details: String, Encodable {
            /// Return only address balances, without any transactions
            case basic
            /// Basic + tokens belonging to the address (applicable only to some coins)
            case tokens
            /// Basic + tokens with balances + belonging to the address (applicable only to some coins)
            case tokenBalances
            /// TokenBalances + list of txids, subject to from, to filter and paging
            case txids
            /// TokenBalances + list of transaction with limited details (only data from index), subject to from, to filter and paging
            case txslight
            /// TokenBalances + list of transaction with details, subject to from, to filter and paging
            case txs
        }

        enum FilterType {
            /// Return only related with coin transactions
            case coin
            /// Return only transactions which affect specified contract (applicable only to coins which support contracts)
            case contract(String)
        }

        enum CodingKeys: CodingKey {
            case page
            case pageSize
            case details
            case contract
            case filter
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(page, forKey: .page)
            try container.encode(pageSize, forKey: .pageSize)
            try container.encode(details.map { $0.rawValue }.joined(separator: ","), forKey: .details)
            switch filterType {
            case .none:
                break
            case .coin:
                // A contributor comment:
                // Actually, there is kind of undocumented feature, if you specify the parameter filter=0
                // it will return only non-contract transactions.
                // We may add some more friendly alias for that and document it in the future.
                // https://github.com/trezor/blockbook/issues/829#issuecomment-1320981721
                try container.encode(0, forKey: .filter)
            case .contract(let contract):
                try container.encode(contract, forKey: .contract)
            }
        }
    }
}
