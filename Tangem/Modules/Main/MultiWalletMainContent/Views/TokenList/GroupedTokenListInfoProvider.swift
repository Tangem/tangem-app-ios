//
//  GroupedTokenListInfoProvider.swift
//  Tangem
//
//  Created by Andrew Son on 03/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

// TODO: This class will be removed in IOS-4157
class GroupedTokenListInfoProvider {
    private let userTokenListManager: UserTokenListManager
    private let walletModelsManager: WalletModelsManager

    private let userWalletId: UserWalletId
    private let currentSections = CurrentValueSubject<[TokenListSectionInfo], Never>([])

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId = .init(with: Data()),
        userTokenListManager: UserTokenListManager,
        walletModelsManager: WalletModelsManager
    ) {
        self.userWalletId = userWalletId
        self.userTokenListManager = userTokenListManager
        self.walletModelsManager = walletModelsManager

        bind()
    }

    private func bind() {
        // FIXME: Removing duplicates is temp solution while waiting sort/group adapter
        userTokenListManager.userTokensPublisher
            .removeDuplicates()
            .combineLatest(walletModelsManager.walletModelsPublisher.removeDuplicates())
            .map(convertToSectionInfo(from:and:))
            .assign(to: \.value, on: currentSections, ownership: .weak)
            .store(in: &bag)
    }

    private func convertToSectionInfo(
        from storageEntries: [StorageEntry.V3.Entry],
        and walletModels: [WalletModel]
    ) -> [TokenListSectionInfo] {
        let storageEntriesGroupedByBlockchainNetworks = Dictionary(grouping: storageEntries, by: \.blockchainNetwork)
        let blockchainNetworksFromStorageEntries = storageEntries
            .unique(by: \.blockchainNetwork)
            .map(\.blockchainNetwork)

        let walletModelsKeyedByIds = walletModels
            .keyedFirst(by: \.id)

        let blockchainNetworksFromWalletModels = walletModelsKeyedByIds
            .values
            .unique(by: \.blockchainNetwork)
            .map(\.blockchainNetwork)
            .toSet()

        return blockchainNetworksFromStorageEntries.reduce(into: []) { partialResult, element in
            guard let storageEntries = storageEntriesGroupedByBlockchainNetworks[element] else { return }

            if blockchainNetworksFromWalletModels.contains(element) {
                let models = storageEntries
                    .compactMap { walletModelsKeyedByIds[$0.walletModelId] }
                    .map { DefaultTokenItemInfoProvider(walletModel: $0) }

                partialResult.append(
                    TokenListSectionInfo(
                        id: element.hashValue,
                        sectionType: .titled(title: title(for: element)),
                        infoProviders: models
                    )
                )
            } else {
                partialResult.append(mapToListSectionInfo(storageEntries, in: element))
            }
        }
    }

    private func mapToListSectionInfo(
        _ storageEntries: [StorageEntry.V3.Entry],
        in blockchainNetwork: StorageEntry.V3.BlockchainNetwork
    ) -> TokenListSectionInfo {
        let converter = StorageEntriesConverter()

        let infoProviders = storageEntries.map { storageEntry in
            let walletModelId = storageEntry.walletModelId

            if let token = converter.convertToToken(storageEntry) {
                return TokenWithoutDerivationInfoProvider(
                    id: walletModelId,
                    tokenItem: .token(token, blockchainNetwork.blockchain)
                )
            }

            return TokenWithoutDerivationInfoProvider(
                id: walletModelId,
                tokenItem: .blockchain(blockchainNetwork.blockchain)
            )
        }

        return .init(
            id: blockchainNetwork.hashValue,
            sectionType: .titled(title: title(for: blockchainNetwork)),
            infoProviders: infoProviders
        )
    }

    private func title(for blockchainNetwork: BlockchainNetwork) -> String {
        Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
    }
}

extension GroupedTokenListInfoProvider: TokenListInfoProvider {
    var sectionsPublisher: AnyPublisher<[TokenListSectionInfo], Never> {
        currentSections.eraseToAnyPublisher()
    }
}
