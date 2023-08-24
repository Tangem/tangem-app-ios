//
//  UserTokenListConverter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 03.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain

struct UserTokenListConverter {
    private let supportedBlockchains: Set<Blockchain>

    init(
        supportedBlockchains: Set<Blockchain>
    ) {
        self.supportedBlockchains = supportedBlockchains
    }

    // MARK: - Stored to Remote

    func convertStoredToRemote(_ storedUserTokenList: StoredUserTokenList) -> UserTokenList {
        let tokens = storedUserTokenList.entries.map { entry in
            return UserTokenList.Token(
                id: entry.id,
                networkId: entry.blockchainNetwork.blockchain.networkId,
                name: entry.name,
                symbol: entry.symbol,
                decimals: entry.decimalCount,
                derivationPath: entry.blockchainNetwork.derivationPath,
                contractAddress: entry.contractAddress
            )
        }

        return UserTokenList(
            tokens: tokens,
            group: convertToGroupType(groupingOption: storedUserTokenList.grouping),
            sort: convertToSortType(sortingOption: storedUserTokenList.sorting)
        )
    }

    private func convertToGroupType(
        groupingOption: StoredUserTokenList.Grouping
    ) -> UserTokenList.GroupType {
        switch groupingOption {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .network
        }
    }

    private func convertToSortType(
        sortingOption: StoredUserTokenList.Sorting
    ) -> UserTokenList.SortType {
        switch sortingOption {
        case .manual:
            return .manual
        case .byBalance:
            return .balance
        }
    }

    // MARK: - Remote to Stored

    func convertRemoteToStored(_ remoteUserTokenList: UserTokenList) -> StoredUserTokenList {
        let entries = remoteUserTokenList.tokens.compactMap { token -> StoredUserTokenList.Entry? in
            guard let blockchain = supportedBlockchains[token.networkId] else {
                return nil
            }

            let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: token.derivationPath)

            return StoredUserTokenList.Entry(
                id: token.id,
                name: token.name,
                symbol: token.symbol,
                decimalCount: token.decimals,
                blockchainNetwork: blockchainNetwork,
                contractAddress: token.contractAddress
            )
        }

        return StoredUserTokenList(
            entries: entries,
            grouping: convertToGroupingOption(groupType: remoteUserTokenList.group),
            sorting: convertToSortingOption(sortType: remoteUserTokenList.sort)
        )
    }

    private func convertToGroupingOption(
        groupType: UserTokenList.GroupType
    ) -> StoredUserTokenList.Grouping {
        switch groupType {
        case .none:
            return .none
        case .network:
            return .byBlockchainNetwork
        }
    }

    private func convertToSortingOption(
        sortType: UserTokenList.SortType
    ) -> StoredUserTokenList.Sorting {
        switch sortType {
        case .manual:
            return .manual
        case .balance:
            return .byBalance
        }
    }
}
