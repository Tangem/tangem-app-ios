//
//  WalletConnectV2Utils.swift
//  Tangem
//
//  Created by Andrew Son on 13/01/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectUtils
import BlockchainSdk
import WalletConnectSign

struct WalletConnectV2Utils {
    /// Validates that all blockchains are supported by BlockchainSdk. Currently (24 Jan 2023) we support only EVM blockchains
    /// All other blockchains such as Solana, Tron, Polkadot using different methods, not `eth_sign`, `eth_sendTransaction` etc.
    /// - Returns:
    /// `Bool` that indicates that all blockchains in session proposal is supported
    func allChainsSupported(in namespaces: [String: ProposalNamespace]) -> Bool {
        for (namespace, proposals) in namespaces {
            guard isNamespaceSupported(namespace) else {
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
    func getBlockchainNamesFromNamespaces(_ namespaces: [String: SessionNamespace], walletModelProvider: WalletConnectWalletModelProvider) -> [String] {
        let blockchainNetworks = mapBlockchainNetworks(from: namespaces, walletModelProvider: walletModelProvider)

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

            if WalletConnectSupportedNamespaces(rawValue: namespace) != nil {
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

                continue
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
    func createSessionNamespaces(
        proposal: Session.Proposal,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws -> [String: SessionNamespace] {
        var missingBlockchains: [String] = []
        var unsupportedEVMBlockchains: [String] = []

        let chains = Set(proposal.namespaceChains)

        var supportedChains = Set<WalletConnectUtils.Blockchain>()

        let accounts: [[Account]] = chains.compactMap { wcBlockchain in
            guard let blockchain = createBlockchain(for: wcBlockchain) else {
                if proposal.namespaceRequiredChains.contains(wcBlockchain) {
                    unsupportedEVMBlockchains.append(wcBlockchain.reference)
                }
                return nil
            }

            supportedChains.insert(wcBlockchain)
            let filteredWallets = walletModelProvider.getModels(with: blockchain.id)
            if filteredWallets.isEmpty {
                missingBlockchains.append(blockchain.displayName)
                return nil
            }

            return filteredWallets.compactMap { Account("\(wcBlockchain.absoluteString):\($0.wallet.address)") }
        }

        let sessionNamespaces = try AutoNamespaces.build(
            sessionProposal: proposal,
            chains: Array(supportedChains),
            methods: proposal.namespaceMethods,
            events: proposal.namespaceEvents,
            accounts: accounts.reduce([], +)
        )

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

    func createBlockchain(for wcBlockchain: WalletConnectUtils.Blockchain) -> BlockchainMeta? {
        guard WalletConnectSupportedNamespaces(rawValue: wcBlockchain.namespace) != nil else {
            return nil
        }

        let blockchains = SupportedBlockchains.all
        let wcChainId = wcBlockchain.reference
        let blockchain = blockchains.first { $0.wcChainID?.contains(wcChainId) ?? false }

        return .init(from: blockchain)
    }

    private func isNamespaceSupported(_ namespace: String) -> Bool {
        WalletConnectSupportedNamespaces(rawValue: namespace) != nil
    }

    private func mapBlockchainNetworks(from namespaces: [String: SessionNamespace], walletModelProvider: WalletConnectWalletModelProvider) -> [BlockchainNetwork] {
        return namespaces.values.flatMap {
            let wcBlockchains = $0.accounts.compactMap { ($0.blockchain, $0.address) }

            let tangemBlockchains = wcBlockchains.compactMap {
                createBlockchainNetwork(from: $0.0, with: $0.1, walletModelProvider: walletModelProvider)
            }
            return tangemBlockchains
        }
    }

    private func createBlockchainNetwork(
        from wcBlockchain: WalletConnectUtils.Blockchain,
        with address: String,
        walletModelProvider: WalletConnectWalletModelProvider
    ) -> BlockchainNetwork? {
        guard
            WalletConnectSupportedNamespaces(rawValue: wcBlockchain.namespace) != nil,
            let blockchain = createBlockchain(for: wcBlockchain),
            let walletModel = try? walletModelProvider.getModel(with: address, blockchainId: blockchain.id)
        else {
            return nil
        }

        return walletModel.blockchainNetwork
    }
}

// MARK: - Supported Namespaces

extension WalletConnectV2Utils {
    enum WalletConnectSupportedNamespaces: String, CaseIterable {
        case eip155
        case solana

        init?(rawValue: String) {
            switch rawValue.lowercased() {
            case "eip155": self = .eip155
            case "solana": self = .solana
            default: return nil
            }
        }
    }
}

// MARK: - Session proposal helper properties for AutoNamespacesBuilder

private extension Session.Proposal {
    var namespaceRequiredChains: Set<WalletConnectUtils.Blockchain> {
        Set(requiredNamespaces.values.compactMap(\.chains).flatMap { $0 })
    }

    var namespaceChains: [WalletConnectUtils.Blockchain] {
        let requiredChains = requiredNamespaces.values.compactMap(\.chains).flatMap { $0.asArray }
        let optionalChains = optionalNamespaces?.values.compactMap(\.chains).flatMap { $0.asArray } ?? []

        return requiredChains + optionalChains
    }

    var namespaceMethods: [String] {
        let requiredMethods = requiredNamespaces.values.flatMap { $0.methods.asArray }
        let optionalMethods = optionalNamespaces?.values.flatMap { $0.methods.asArray } ?? []

        return requiredMethods + optionalMethods
    }

    var namespaceEvents: [String] {
        let requiredEvents = requiredNamespaces.values.flatMap { $0.events.asArray }
        let optionalEvents = optionalNamespaces?.values.flatMap { $0.events.asArray } ?? []

        return requiredEvents + optionalEvents
    }
}
