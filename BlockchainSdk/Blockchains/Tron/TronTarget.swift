//
//  TronTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TronTarget: TargetType {
    enum TronTargetType {
        case getChainParameters
        case getAccount(address: String)
        case getAccountResource(address: String)
        case getNowBlock
        case broadcastHex(data: Data)
        case tokenBalance(address: String, contractAddress: String, parameter: String)
        case contractEnergyUsage(sourceAddress: String, contractAddress: String, parameter: String)
        case getTransactionInfoById(transactionID: String)
        case getAllowance(sourceAddress: String, contractAddress: String, parameter: String)
    }
    
    let node: NodeInfo
    let type: TronTargetType
    
    init(node: NodeInfo, _ type: TronTargetType) {
        self.node = node
        self.type = type
    }

    var baseURL: URL {
        node.url
    }

    var path: String {
        switch type {
        case .getChainParameters:
            return "/wallet/getchainparameters"
        case .getAccount:
            return "/wallet/getaccount"
        case .getAccountResource:
            return "/wallet/getaccountresource"
        case .getNowBlock:
            return "/wallet/getnowblock"
        case .broadcastHex:
            return "/wallet/broadcasthex"
        case .tokenBalance, .contractEnergyUsage, .getAllowance:
            return "/wallet/triggerconstantcontract"
        case .getTransactionInfoById:
            return "/walletsolidity/gettransactioninfobyid"
        }
    }
    
    var method: Moya.Method {
        .post
    }
    
    var task: Task {
        switch type {
        case .getChainParameters:
            return .requestPlain
        case .getAccount(let address), .getAccountResource(let address):
            let request = TronGetAccountRequest(address: address, visible: true)
            return .requestJSONEncodable(request)
        case .getNowBlock:
            return .requestPlain
        case .broadcastHex(let data):
            let request = TronBroadcastRequest(transaction: data.hexString.lowercased())
            return .requestJSONEncodable(request)
        case .tokenBalance(let address, let contractAddress, let parameter):
            let request = TronTriggerSmartContractRequest(
                owner_address: address,
                contract_address: contractAddress,
                function_selector: TronFunction.balanceOf.rawValue,
                parameter: parameter,
                visible: true
            )
            return .requestJSONEncodable(request)
        case .contractEnergyUsage(let sourceAddress, let contractAddress, let parameter):
            let request = TronTriggerSmartContractRequest(
                owner_address: sourceAddress,
                contract_address: contractAddress,
                function_selector: TronFunction.transfer.rawValue,
                parameter: parameter,
                visible: true
            )
            return .requestJSONEncodable(request)
        case .getTransactionInfoById(let transactionID):
            let request = TronTransactionInfoRequest(value: transactionID)
            return .requestJSONEncodable(request)
        case .getAllowance(let sourceAddress, let contractAddress, let parameter):
            let request = TronTriggerSmartContractRequest(
                owner_address: sourceAddress,
                contract_address: contractAddress,
                function_selector: TronFunction.allowance.rawValue,
                parameter: parameter,
                visible: true
            )
            return .requestJSONEncodable(request)

        }
    }
    
    var headers: [String : String]? {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        
        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }
        
        return headers
    }
}
