//
//  WalletConnectV2Service.swift
//  Tangem
//
//  Created by Andrew Son on 22/12/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletConnectSwiftV2
import BlockchainSdk

protocol WalletConnectUserWalletInfoProvider {
    var userWalletId: UserWalletId { get }
    var signer: TangemSigner { get }
    var wcWalletModelProvider: WalletConnectWalletModelProvider { get }
}

final class WalletConnectV2Service {
    @Injected(\.walletConnectSessionsStorage) private var sessionsStorage: WalletConnectSessionsStorage
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let factory = WalletConnectV2DefaultSocketFactory()
    private let uiDelegate: WalletConnectUIDelegate
    private let messageComposer: WalletConnectV2MessageComposable
    private let wcHandlersService: WalletConnectV2HandlersServicing

    private var canEstablishNewSessionSubject: CurrentValueSubject<Bool, Never> = .init(true)
    private var sessionSubscriptions = Set<AnyCancellable>()
    private var messagesSubscriptions = Set<AnyCancellable>()

    private lazy var pairApi: PairingInteracting = Pair.instance
    private lazy var signApi: SignClient = Sign.instance

    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        canEstablishNewSessionSubject
            .eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await sessionsStorage.sessions
        }
    }

    private var infoProvider: WalletConnectUserWalletInfoProvider?

    init(
        uiDelegate: WalletConnectUIDelegate,
        messageComposer: WalletConnectV2MessageComposable,
        wcHandlersService: WalletConnectV2HandlersServicing
    ) {
        self.uiDelegate = uiDelegate
        self.messageComposer = messageComposer
        self.wcHandlersService = wcHandlersService

        Networking.configure(
            projectId: keysManager.walletConnectProjectId,
            socketFactory: factory,
            socketConnectionType: .automatic
        )
        Pair.configure(metadata: AppMetadata(
            name: "Tangem iOS",
            description: "Tangem is a card-shaped self-custodial cold hardware wallet",
            url: "tangem.com",
            icons: ["https://user-images.githubusercontent.com/24321494/124071202-72a00900-da58-11eb-935a-dcdab21de52b.png"]
        ))

        setupSessionSubscriptions()
        setupMessagesSubscriptions()
    }

    func initialize(with infoProvider: WalletConnectUserWalletInfoProvider) {
        self.infoProvider = infoProvider
        runTask { [weak self] in
            await self?.sessionsStorage.loadSessions()
        }
    }

    func openSession(with uri: WalletConnectV2URI) {
        canEstablishNewSessionSubject.send(false)
        runTask(withTimeout: 20) { [weak self] in
            await self?.pairClient(with: uri)
            self?.canEstablishNewSessionSubject.send(true)
        } onTimeout: { [weak self] in
            self?.displayErrorUI(WalletConnectV2Error.sessionConnetionTimeout)
            self?.canEstablishNewSessionSubject.send(true)
        }
    }

    func disconnectSession(with id: Int) async {
        guard let session = await sessionsStorage.session(with: id) else { return }

        do {
            try await signApi.disconnect(topic: session.topic)

            Analytics.log(
                event: .sessionDisconnected,
                params: [
                    .dAppName: session.sessionInfo.dAppInfo.name,
                    .dAppUrl: session.sessionInfo.dAppInfo.url,
                ]
            )

            await sessionsStorage.remove(session)
        } catch {
            let internalError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)
            if case .sessionForTopicNotFound = internalError {
                await sessionsStorage.remove(session)
                return
            }
            AppLog.shared.error("[WC 2.0] Failed to disconnect session with topic: \(session.topic) with error: \(error)")
        }
    }

    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        runTask { [weak self] in
            guard let self else { return }

            let removedSessions = await sessionsStorage.removeSessions(for: userWalletId)
            for session in removedSessions {
                do {
                    try await signApi.disconnect(topic: session.topic)
                } catch {
                    AppLog.shared.error("[WC 2.0] Failed to disconnect session while disconnecting all sessions for user wallet with id: \(userWalletId). Error: \(error)")
                }
            }
        }
    }

    private func pairClient(with url: WalletConnectURI) async {
        log("Trying to pair client: \(url)")
        do {
            try await pairApi.pair(uri: url)
            try Task.checkCancellation()
            log("Established pair for \(url)")
        } catch {
            displayErrorUI(WalletConnectV2Error.pairClientError(error.localizedDescription))
            AppLog.shared.error("[WC 2.0] Failed to connect to \(url) with error: \(error)")

            // Hack to delete the topic from the user default storage inside the WC 2.0 SDK
            await disconnect(topic: url.topic)
        }
    }

    private func disconnect(topic: String) async {
        do {
            try await pairApi.disconnect(topic: topic)
            log("Success disconnect/delete topic \(topic)")
        } catch {
            AppLog.shared.error("[WC 2.0] Failed to disconnect/delete topic \(topic) with error: \(error)")
        }
    }

    // MARK: - Subscriptions

    private func setupSessionSubscriptions() {
        signApi.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal, context in
                self?.log("Session proposal: \(sessionProposal) with verify context: \(String(describing: context))")
                self?.validateProposal(sessionProposal)
            }
            .store(in: &sessionSubscriptions)

        signApi.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] session in
                guard let self else { return }

                if infoProvider == nil {
                    log("Info provider is not setup. Saved session will miss some info")
                }

                log("Session established: \(session)")
                let savedSession = WalletConnectV2Utils().createSavedSession(
                    from: session,
                    with: infoProvider?.userWalletId.stringValue ?? ""
                )

                Analytics.log(
                    event: .newSessionEstablished,
                    params: [
                        .dAppName: session.peer.name,
                        .dAppUrl: session.peer.url,
                    ]
                )

                await sessionsStorage.save(savedSession)
            }
            .sink()
            .store(in: &sessionSubscriptions)

        signApi.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] topic, reason in
                guard let self else { return }

                log("Receive Delete session message with topic: \(topic). Delete reason: \(reason)")

                guard let session = await sessionsStorage.session(with: topic) else {
                    return
                }

                Analytics.log(
                    event: .sessionDisconnected,
                    params: [
                        .dAppName: session.sessionInfo.dAppInfo.name,
                        .dAppUrl: session.sessionInfo.dAppInfo.url,
                    ]
                )

                log("Session with topic (\(topic)) was found. Deleting session from storage...")
                await sessionsStorage.remove(session)
            }
            .sink()
            .store(in: &sessionSubscriptions)
    }

    private func setupMessagesSubscriptions() {
        signApi.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .asyncMap { [weak self] request, context in
                guard let self else { return }

                log("Receive message request: \(request) with verify context: \(String(describing: context))")
                await handle(request)
            }
            .sink()
            .store(in: &messagesSubscriptions)
    }

    private func validateProposal(_ proposal: Session.Proposal) {
        let utils = WalletConnectV2Utils()
        log("Attemping to approve session proposal: \(proposal)")

        guard let infoProvider else {
            displayErrorUI(.missingActiveUserWalletModel)
            sessionRejected(with: proposal)
            return
        }

        guard DApps().isSupported(proposal.proposer.url) else {
            displayErrorUI(.unsupportedDApp)
            sessionRejected(with: proposal)
            return
        }

        guard utils.allChainsSupported(in: proposal.requiredNamespaces) else {
            let unsupportedBlockchains = utils.extractUnsupportedBlockchainNames(from: proposal.requiredNamespaces)
            displayErrorUI(.unsupportedBlockchains(unsupportedBlockchains))
            sessionRejected(with: proposal)
            return
        }

        do {
            let sessionNamespaces = try utils.createSessionNamespaces(
                from: proposal.requiredNamespaces,
                optionalNamespaces: proposal.optionalNamespaces,
                walletModelProvider: infoProvider.wcWalletModelProvider
            )
            displaySessionConnectionUI(for: proposal, namespaces: sessionNamespaces)
        } catch let error as WalletConnectV2Error {
            displayErrorUI(error)
        } catch {
            AppLog.shared.error("[WC 2.0] \(error)")
            displayErrorUI(.unknown(error.localizedDescription))
        }
    }

    // MARK: - UI Related

    private func displaySessionConnectionUI(for proposal: Session.Proposal, namespaces: [String: SessionNamespace]) {
        log("Did receive session proposal")

        guard let infoProvider else {
            displayErrorUI(.missingActiveUserWalletModel)
            sessionRejected(with: proposal)
            return
        }

        let blockchains = WalletConnectV2Utils().getBlockchainNamesFromNamespaces(namespaces, walletModelProvider: infoProvider.wcWalletModelProvider)
        let message = messageComposer.makeMessage(for: proposal, targetBlockchains: blockchains)
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .establishSession,
            message: message,
            approveAction: { [weak self] in
                self?.sessionAccepted(with: proposal.id, namespaces: namespaces)
            },
            rejectAction: { [weak self] in
                self?.sessionRejected(with: proposal)
            }
        ))
    }

    private func displayErrorUI(_ error: WalletConnectV2Error) {
        uiDelegate.showScreen(with: WalletConnectUIRequest(
            event: .error,
            message: error.localizedDescription,
            approveAction: {}
        ))
    }

    // MARK: - Session manipulation

    private func sessionAccepted(with id: String, namespaces: [String: SessionNamespace]) {
        runTask { [weak self] in
            guard let self else { return }

            do {
                log("Namespaces to approve for session connection: \(namespaces)")
                try await signApi.approve(proposalId: id, namespaces: namespaces)
            } catch let error as WalletConnectV2Error {
                self.displayErrorUI(error)
            } catch {
                let mappedError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)
                displayErrorUI(mappedError)
                AppLog.shared.error("[WC 2.0] Failed to approve Session with error: \(error)")
            }
        }
    }

    private func sessionRejected(with proposal: Session.Proposal) {
        runTask { [weak self] in
            do {
                try await self?.signApi.reject(proposalId: proposal.id, reason: .userRejected)
                self?.log("User reject WC connection")
            } catch {
                AppLog.shared.error("[WC 2.0] Failed to reject WC connection with error: \(error)")
            }
        }
    }

    // MARK: - Message handling

    private func handle(_ request: Request) async {
        func respond(
            with error: WalletConnectV2Error,
            session: WalletConnectSavedSession?,
            blockchainCurrencySymbol: String?
        ) async {
            AppLog.shared.error(error)

            logAnalytics(
                request: request,
                session: session,
                blockchainCurrencySymbol: blockchainCurrencySymbol,
                error: error
            )

            try? await signApi.respond(
                topic: request.topic,
                requestId: request.id,
                response: .error(.init(code: 0, message: error.localizedDescription))
            )
        }

        let logSuffix = " for request: \(request)"
        let utils = WalletConnectV2Utils()

        guard let targetBlockchain = utils.createBlockchain(for: request.chainId) else {
            log("Failed to create blockchain \(logSuffix)")
            await respond(with: .missingBlockchains([request.chainId.absoluteString]), session: nil, blockchainCurrencySymbol: nil)
            return
        }

        if userWalletRepository.isLocked, userWalletRepository.models.isEmpty {
            log("User wallet repository is locked")
            await respond(with: .userWalletRepositoryIsLocked, session: nil, blockchainCurrencySymbol: targetBlockchain.currencySymbol)
            return
        }

        guard let session = await sessionsStorage.session(with: request.topic) else {
            log("Failed to find session in storage \(logSuffix)")
            await respond(with: .wrongCardSelected, session: nil, blockchainCurrencySymbol: targetBlockchain.currencySymbol)
            return
        }

        guard let userWallet = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == session.userWalletId }) else {
            log("Failed to find target user wallet")
            await respond(with: .missingActiveUserWalletModel, session: session, blockchainCurrencySymbol: targetBlockchain.currencySymbol)
            return
        }

        if userWallet.userWallet.isLocked {
            log("Attempt to handle message with locked user wallet")
            await respond(with: .userWalletIsLocked, session: session, blockchainCurrencySymbol: targetBlockchain.currencySymbol)
            return
        }

        do {
            let result = try await wcHandlersService.handle(
                request,
                from: session.sessionInfo.dAppInfo,
                blockchainId: targetBlockchain.id,
                signer: userWallet.signer,
                walletModelProvider: CommonWalletConnectWalletModelProvider(walletModelsManager: userWallet.walletModelsManager) // Actuallty don't know where this generation should be...
            )

            log("Receive result from user \(result) for \(logSuffix)")
            try await signApi.respond(topic: session.topic, requestId: request.id, response: result)

            logAnalytics(
                request: request,
                session: session,
                blockchainCurrencySymbol: targetBlockchain.currencySymbol,
                error: nil
            )

        } catch let error as WalletConnectV2Error {
            if case .unsupportedWCMethod = error {} else {
                displayErrorUI(error)
            }
            await respond(with: error, session: session, blockchainCurrencySymbol: targetBlockchain.currencySymbol)
        } catch {
            let wcError: WalletConnectV2Error = .unknown(error.localizedDescription)
            displayErrorUI(wcError)
            await respond(with: wcError, session: session, blockchainCurrencySymbol: targetBlockchain.currencySymbol)
        }
    }

    // MARK: - Utils

    private func logAnalytics(
        request: Request,
        session: WalletConnectSavedSession?,
        blockchainCurrencySymbol: String?,
        error: WalletConnectV2Error?
    ) {
        var params: [Analytics.ParameterKey: String] = [:]

        if let session {
            params[.dAppName] = session.sessionInfo.dAppInfo.name
            params[.dAppUrl] = session.sessionInfo.dAppInfo.url
        }

        if let blockchainCurrencySymbol {
            params[.blockchain] = blockchainCurrencySymbol
        }

        params[.methodName] = request.method

        if let error {
            params[.validation] = Analytics.ParameterValue.fail.rawValue
            params[.errorCode] = "\(error.code)"
        } else {
            params[.validation] = Analytics.ParameterValue.success.rawValue
        }

        Analytics.log(event: .requestHandled, params: params)
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[WC 2.0] \(message())")
    }
}

public typealias WalletConnectV2URI = WalletConnectURI

private struct DApps {
    private let unsupportedList: [String] = ["dydx.exchange"]

    func isSupported(_ dAppURL: String) -> Bool {
        for dApp in unsupportedList {
            if dAppURL.contains(dApp) {
                return false
            }
        }

        return true
    }
}
