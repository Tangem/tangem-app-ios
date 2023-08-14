//
//  OrganizeWalletModelsAdapter.swift
//  Tangem
//
//  Created by Andrey Fedorov on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import struct BlockchainSdk.Amount // TODO: Andrey Fedorov - Remove after migration to actual types from the domain layer (IOS-4152)
import enum BlockchainSdk.Blockchain // TODO: Andrey Fedorov - Remove after migration to actual types from the domain layer (IOS-4152)

final class OrganizeWalletModelsAdapter {
    typealias Section = OrganizeWalletModelsSection<SectionType>
    typealias UserToken = UserTokenList.Token // TODO: Andrey Fedorov - Replace with actual types from the domain layer (IOS-4152)
    typealias GroupingOption = OrganizeTokensOptions.Grouping
    typealias SortingOption = OrganizeTokensOptions.Sorting

    enum SectionType {
        case group(by: BlockchainNetwork)
        case plain
    }

    private let userTokenListManager: UserTokenListManager
    private let walletModelComponentsBuilder: WalletModelComponentsBuilder
    private let organizeTokensOptionsProviding: OrganizeTokensOptionsProviding
    private let organizeTokensOptionsEditing: OrganizeTokensOptionsEditing

    init(
        userTokenListManager: UserTokenListManager,
        walletModelComponentsBuilder: WalletModelComponentsBuilder,
        organizeTokensOptionsProviding: OrganizeTokensOptionsProviding,
        organizeTokensOptionsEditing: OrganizeTokensOptionsEditing
    ) {
        self.userTokenListManager = userTokenListManager
        self.walletModelComponentsBuilder = walletModelComponentsBuilder
        self.organizeTokensOptionsProviding = organizeTokensOptionsProviding
        self.organizeTokensOptionsEditing = organizeTokensOptionsEditing
    }

    func organizedWalletModels(
        from walletModels: some Publisher<[WalletModel], Never>,
        on workingQueue: DispatchQueue
    ) -> some Publisher<[Section], Never> {
        return walletModels
            .combineLatest(
                userTokenListManager.userTokenList.map(\.tokens),
                organizeTokensOptionsProviding.groupingOption,
                organizeTokensOptionsProviding.sortingOption
            )
            .receive(on: workingQueue)
            .withWeakCaptureOf(self)
            .map { input in
                let (adapter, (walletModels, userTokens, groupingOption, sortingOption)) = input
                return adapter.makeSections(
                    walletModels: walletModels,
                    userTokens: userTokens,
                    groupingOption: groupingOption,
                    sortingOption: sortingOption
                )
            }
    }

    private func makeSections(
        walletModels: [WalletModel],
        userTokens: [UserToken],
        groupingOption: GroupingOption,
        sortingOption: SortingOption
    ) -> [Section] {
        let walletModelsKeyedByID = walletModels
            .keyedFirst(by: \.id)

        switch groupingOption {
        case .byBlockchainNetwork:
            return makeGroupedSections(
                walletModelsKeyedByID: walletModelsKeyedByID,
                userTokens: userTokens,
                sortingOption: sortingOption
            )
        case .none:
            return makePlainSections(
                walletModelsKeyedByID: walletModelsKeyedByID,
                userTokens: userTokens,
                sortingOption: sortingOption
            )
        }
    }

    private func makeGroupedSections(
        walletModelsKeyedByID: [WalletModel.ID: WalletModel],
        userTokens: [UserToken],
        sortingOption: SortingOption
    ) -> [Section] {
        let blockchainNetworks = userTokens
            .compactMap { walletModelComponentsBuilder.buildBlockchainNetwork(from: $0) }
            .unique()

        let userTokensGroupedByBlockchainNetworks: [BlockchainNetwork: [UserToken]] = userTokens
            .reduce(into: [:]) { partialResult, element in
                guard let blockchainNetwork = walletModelComponentsBuilder.buildBlockchainNetwork(from: element) else {
                    return
                }

                partialResult[blockchainNetwork, default: []].append(element)
            }

        return blockchainNetworks.map { blockchainNetwork in
            let userTokensForBlockchainNetwork = userTokensGroupedByBlockchainNetworks[blockchainNetwork, default: []]
            let walletModelsForBlockchainNetwork = userTokensForBlockchainNetwork.compactMap { token -> WalletModel? in
                guard let walletModelID = walletModelComponentsBuilder.buildWalletModelID(from: token) else {
                    return nil
                }

                return walletModelsKeyedByID[walletModelID]
            }
            let sortedWalletModelsForBlockchainNetwork = self.walletModels(
                walletModelsForBlockchainNetwork,
                sortedBy: sortingOption
            )
            return Section(
                model: .group(by: blockchainNetwork),
                items: sortedWalletModelsForBlockchainNetwork
            )
        }
    }

    private func makePlainSections(
        walletModelsKeyedByID: [WalletModel.ID: WalletModel],
        userTokens: [UserToken],
        sortingOption: SortingOption
    ) -> [Section] {
        let walletModels = userTokens.compactMap { token -> WalletModel? in
            guard let walletModelID = walletModelComponentsBuilder.buildWalletModelID(from: token) else {
                return nil
            }

            return walletModelsKeyedByID[walletModelID]
        }
        let sortedWalletModels = self.walletModels(
            walletModels,
            sortedBy: sortingOption
        )

        return [
            Section(
                model: .plain,
                items: sortedWalletModels
            ),
        ]
    }

    private func walletModels(
        _ walletModels: [WalletModel],
        sortedBy sortingOption: SortingOption
    ) -> [WalletModel] {
        switch sortingOption {
        case .dragAndDrop:
            // Keeping existing sort order
            return walletModels
        case .byBalance:
            // The underlying sorting algorithm is guaranteed to be stable in Swift 5.0 and above
            // For cases when both lhs and rhs values are nil we also maintain a stable order of such elements
            return walletModels.sorted { lhs, rhs in
                switch (lhs.fiatValue, rhs.fiatValue) {
                case (.some, .none):
                    return true
                case (.none, .some), (.none, .none):
                    return false
                case (.some(let lhsFiatValue), .some(let rhsFiatValue)):
                    return lhsFiatValue > rhsFiatValue
                }
            }
        }
    }
}
