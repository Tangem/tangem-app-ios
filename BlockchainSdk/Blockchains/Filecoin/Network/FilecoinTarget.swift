//
//  FilecoinTarget.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct FilecoinTarget: TargetType {
    enum FilecoinTargetType {
        case getActorInfo(address: String)
        case getEstimateMessageGas(message: FilecoinMessage)
        case submitTransaction(signedMessage: FilecoinSignedMessage)

        var method: String {
            switch self {
            case .getActorInfo:
                "Filecoin.StateGetActor"
            case .getEstimateMessageGas:
                "Filecoin.GasEstimateMessageGas"
            case .submitTransaction:
                "Filecoin.MpoolPush"
            }
        }
    }

    let node: NodeInfo
    let type: FilecoinTargetType

    init(node: NodeInfo, _ type: FilecoinTargetType) {
        self.node = node
        self.type = type
    }

    var baseURL: URL {
        node.url
    }

    var path: String {
        ""
    }

    var method: Moya.Method {
        .post
    }

    var task: Task {
        switch type {
        case .getActorInfo(let address):
            .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: [
                    address,
                    nil,
                ]
            )

        case .getEstimateMessageGas(let message):
            .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: [
                    message,
                    nil,
                    nil,
                ]
            )

        case .submitTransaction(let signedMessage):
            .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: [
                    signedMessage,
                ]
            )
        }
    }

    var headers: [String: String]?
}

private extension FilecoinTarget {
    enum Constants {
        static let jsonRPCMethodId: Int = 1
    }
}
