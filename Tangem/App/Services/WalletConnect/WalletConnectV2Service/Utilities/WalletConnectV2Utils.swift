//
//  WalletConnectV2Utils.swift
//  Tangem
//
//  Created by Andrew Son on 13/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwiftV2
import BlockchainSdk

struct WalletConnectV2Utils {
    private let evmNamespace = "eip155"

    /// Validates that all blockchains are supported by BlockchainSdk. Currently (24 Jan 2023) we support only EVM blockchains
    /// All other blockchains such as Solana, Tron, Polkadot using different methods, not `eth_sign`, `eth_sendTransaction` etc.
    /// - Returns:
    /// `Bool` that indicates that all blockchains in session proposal is supported
    func allChainsSupported(in namespaces: [String: ProposalNamespace]) -> Bool {
        for (namespace, proposals) in namespaces {
            if namespace != evmNamespace {
                return false
            }

            let blockchains = proposals.chains?.compactMap(createBlockchain(for:))
            if blockchains?.count != proposals.chains?.count {
                return false
            }
        }

        return true
    }

    /// Attempts to create `BlockchainNetwork` for each session namespace. This can be used for displaying Blockchain name for user
    /// in an alert with new session connection request
    /// - Returns:
    /// Array of strings with the blockchain names
    func getBlockchainNamesFromNamespaces(_ namespaces: [String: SessionNamespace], using walletModels: [WalletModel]) -> [String] {
        let blockchainNetworks = mapBlockchainNetworks(from: namespaces, using: walletModels)

        return blockchainNetworks.map { $0.blockchain.displayName }
    }

    /// If not all blockchains in session proposal request are supported this method will extract all of the not supported blockchain names and capitalize first letter
    /// Capitalization is needed because all blockchain (`chainis` in `WalletConnectSwiftV2` terminology)  in proposal stored as lowercased, e.g. `solana`, `polkadot`
    /// - Returns:
    /// Array of Strings with unsupported blockchain names
    func extractUnsupportedBlockchainNames(from namespaces: [String: ProposalNamespace]) -> [String] {
        var blockchains = [String]()
        for (namespace, proposal) in namespaces {
            guard let chains = proposal.chains else {
                continue
            }

            if namespace == evmNamespace {
                let notSupportedEVMChainIds: [String] = chains.compactMap { chain in
                    guard createBlockchain(for: chain) == nil else {
                        return nil
                    }

                    return chain.absoluteString
                }

                blockchains.append(contentsOf: notSupportedEVMChainIds)
            } else {
                let notEVMChainNames = chains.map { chain in
                    return createBlockchain(for: chain)?.displayName ?? namespace.capitalizingFirstLetter()
                }

                blockchains.append(contentsOf: notEVMChainNames)
            }
        }

        return blockchains
    }

    /// Wallet must convert all `ProposalNamespace` into `SessionNamespace` with corresponding `Account`s and send session approve to `SignApi`
    /// - Note:
    /// We can use multiple `Account`s for single blockchain. E.g. if user attempting to connect to ETH blockchain if we can create
    /// multiple addresses (using derivation), then we can create `Account`s and they will be displayed in dApp UI. At least in demo dApp it works)
    /// - Returns:
    /// Dictionary with `chains` (`WalletConnectSwiftV2` terminology) as keys and session settings as values.
    /// - Throws:Error with list of unsupported blockchain names or a list of not added to user token list blockchain names
    func createSessionNamespaces(from namespaces: [String: ProposalNamespace], optionalNamespaces: [String: ProposalNamespace]?, for wallets: [WalletModel]) throws -> [String: SessionNamespace] {
        let wallets = wallets.filter { $0.isMainToken }
        var sessionNamespaces: [String: SessionNamespace] = [:]
        var missingBlockchains: [String] = []
        var unsupportedEVMBlockchains: [String] = []

        for (namespace, proposalNamespace) in namespaces {
            guard let chains = proposalNamespace.chains else {
                continue
            }

            var supportedChains = Set<WalletConnectSwiftV2.Blockchain>()
            let accounts: [[Account]] = chains.compactMap { wcBlockchain in
                guard let blockchain = createBlockchain(for: wcBlockchain) else {
                    unsupportedEVMBlockchains.append(wcBlockchain.reference)
                    return nil
                }

                supportedChains.insert(wcBlockchain)
                let filteredWallets = wallets.filter { $0.blockchainNetwork.blockchain.coinId == blockchain.id }
                if filteredWallets.isEmpty {
                    missingBlockchains.append(blockchain.displayName)
                    return nil
                }

                return filteredWallets.compactMap { Account("\(wcBlockchain.absoluteString):\($0.wallet.address)") }
            }

            let sessionNamespace = SessionNamespace(
                chains: supportedChains,
                accounts: Set(accounts.reduce([], +)),
                methods: proposalNamespace.methods,
                events: proposalNamespace.events
            )
            sessionNamespaces[namespace] = sessionNamespace
        }

        for (namespace, proposalNamespace) in optionalNamespaces ?? [:] {
            guard let chains = proposalNamespace.chains else {
                continue
            }

            var supportedChains = Set<WalletConnectSwiftV2.Blockchain>()
            let accounts: [[Account]] = chains.compactMap { wcBlockchain in
                guard let blockchain = createBlockchain(for: wcBlockchain) else {
                    return nil
                }

                supportedChains.insert(wcBlockchain)
                let filteredWallets = wallets.filter { $0.blockchainNetwork.blockchain.coinId == blockchain.id }
                if filteredWallets.isEmpty {
                    return nil
                }

                return filteredWallets.compactMap { Account("\(wcBlockchain.absoluteString):\($0.wallet.address)") }
            }

            let sessionNamespace = SessionNamespace(
                chains: supportedChains,
                accounts: Set(accounts.reduce([], +)),
                methods: proposalNamespace.methods,
                events: proposalNamespace.events
            )

            // TODO: TBF WTF? :)
            if let existingNamespace = sessionNamespaces[namespace] {
                let unionChains = existingNamespace.chains?.union(sessionNamespace.chains ?? [])
                let unionAccounts = existingNamespace.accounts.union(sessionNamespace.accounts)
                let unionMethods = existingNamespace.methods.union(sessionNamespace.methods)
                let unionEvents = existingNamespace.events.union(sessionNamespace.events)
                sessionNamespaces[namespace] = SessionNamespace(
                    chains: unionChains,
                    accounts: unionAccounts,
                    methods: unionMethods,
                    events: unionEvents
                )
            } else {
                sessionNamespaces[namespace] = sessionNamespace
            }
        }

        guard unsupportedEVMBlockchains.isEmpty else {
            throw WalletConnectV2Error.unsupportedBlockchains(unsupportedEVMBlockchains)
        }

        guard missingBlockchains.isEmpty else {
            throw WalletConnectV2Error.missingBlockchains(missingBlockchains)
        }

        return sessionNamespaces
    }

    /// Method for creating internal session structure for storing on disk. Used for finding information about wallet using session topic.
    /// Also used in UI to display list of connected WC sessions for selected Wallet
    /// - Returns: `WalletConnectSavedSession` with info about wallet, dApp and session
    func createSavedSession(from session: Session, with userWalletId: String) -> WalletConnectSavedSession {
        let dApp = session.peer
        let dAppInfo = WalletConnectSavedSession.DAppInfo(
            name: dApp.name,
            description: dApp.description,
            url: dApp.url,
            iconLinks: dApp.icons
        )
        let sessionInfo = WalletConnectSavedSession.SessionInfo(
            dAppInfo: dAppInfo
        )

        return WalletConnectSavedSession(
            userWalletId: userWalletId,
            topic: session.topic,
            sessionInfo: sessionInfo
        )
    }

    func createBlockchain(for wcBlockchain: WalletConnectSwiftV2.Blockchain) -> BlockchainMeta? {
        switch wcBlockchain.namespace {
        case evmNamespace:
            let blockchains = SupportedBlockchains.all
            let wcChainId = Int(wcBlockchain.reference)
            return blockchains
                .first(where: { $0.chainId == wcChainId })
                .map {
                    BlockchainMeta(
                        id: $0.coinId,
                        currencySymbol: $0.currencySymbol,
                        displayName: $0.displayName
                    )
                }
        default:
            return nil
        }
    }

    private func mapBlockchainNetworks(from namespaces: [String: SessionNamespace], using wallets: [WalletModel]) -> [BlockchainNetwork] {
        return namespaces.values.flatMap {
            let wcBlockchains = $0.accounts.compactMap { ($0.blockchain, $0.address) }

            let tangemBlockchains = wcBlockchains.compactMap {
                createBlockchainNetwork(from: $0.0, with: $0.1, using: wallets)
            }
            return tangemBlockchains
        }
    }

    private func createBlockchainNetwork(
        from wcBlockchain: WalletConnectSwiftV2.Blockchain,
        with address: String,
        using walletModels: [WalletModel]
    ) -> BlockchainNetwork? {
        switch wcBlockchain.namespace {
        case evmNamespace:
            guard
                let blockchain = createBlockchain(for: wcBlockchain),
                let walletModel = walletModels.first(where: { $0.wallet.blockchain.coinId == blockchain.id && $0.wallet.address == address })
            else {
                return nil
            }

            return walletModel.blockchainNetwork
        default:
            return nil
        }
    }
}

struct BlockchainMeta {
    let id: String
    let currencySymbol: String
    let displayName: String
}
