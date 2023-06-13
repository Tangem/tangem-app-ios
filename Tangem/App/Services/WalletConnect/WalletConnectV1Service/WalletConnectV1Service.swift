//
//  WalletConnectService.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import WalletConnectSwift
import Combine
import BlockchainSdk
import TangemSdk

class WalletConnectV1Service {
    let canEstablishNewSessionPublisher = CurrentValueSubject<Bool, Never>(true)

    @Published private(set) var sessions = [WalletConnectSession]()
    var sessionsPublisher: AnyPublisher<[WalletConnectSession], Never> {
        $sessions
            .map { [weak self] wcSessions in
                guard let self = self else { return [] }

                return wcSessions.filter { $0.wallet.walletPublicKey == self.cardModel.secp256k1SeedKey }
            }
            .eraseToAnyPublisher()
    }

    private(set) var cardModel: CardViewModel

    private var wallet: WalletInfo?

    private var server: Server!
    private let updateQueue = DispatchQueue(label: "ws_sessions_update_queue")
    private let sessionsKey = "wc_sessions"

    private var isWaitingToConnect: Bool = false
    private var timer: DispatchWorkItem?

    init(with cardModel: CardViewModel) {
        self.cardModel = cardModel
        server = Server(delegate: self)
        server.register(handler: PersonalSignHandler(delegate: self, dataSource: self))
        server.register(handler: SignTransactionHandler(delegate: self, dataSource: self))
        server.register(handler: SendTransactionHandler(delegate: self, dataSource: self))
        server.register(handler: BnbSignHandler(delegate: self, dataSource: self))
        server.register(handler: BnbSuccessHandler(delegate: self, dataSource: self))
        server.register(handler: SignTypedDataHandler(delegate: self, dataSource: self))
        server.register(handler: SignTypedDataHandlerV4(delegate: self, dataSource: self))
        server.register(handler: SwitchChainHandler(delegate: self, dataSource: self))
        restore()
    }

    deinit {
        AppLog.shared.debug("WalletConnectService deinit")
    }

    func openSession(with uri: WalletConnectV1URI) {
        connect(to: uri)
    }

    private func restore() {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let decoder = JSONDecoder()
            if let oldSessionsObject = UserDefaults.standard.object(forKey: sessionsKey) as? Data {
                let decodedSessions = (try? decoder.decode([WalletConnectSession].self, from: oldSessionsObject)) ?? []

                // TODO: Refactor. We can use seed keys as identifiers for sessions now.
                let filteredSessions = decodedSessions.filter { $0.wallet.walletPublicKey == self.cardModel.secp256k1SeedKey }
                filteredSessions.forEach {
                    do {
                        try self.server.reconnect(to: $0.session)
                    } catch {
                        self.handle(WalletConnectServiceError.other(error))
                    }
                }

                DispatchQueue.main.async {
                    self.sessions = decodedSessions
                }
            }
        }
    }

    private func connect(to url: WCURL) {
        setupSessionConnectTimer()
        do {
            try server.connect(to: url)
            Analytics.log(.newSessionEstablished)
        } catch {
            AppLog.shared.error(error)
            resetSessionConnectTimer()
            handle(error)
            canEstablishNewSessionPublisher.send(true)
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        if let sessionsData = try? encoder.encode(sessions) {
            UserDefaults.standard.set(sessionsData, forKey: sessionsKey)
        }
    }

    private func setupSessionConnectTimer() {
        isWaitingToConnect = true
        canEstablishNewSessionPublisher.send(false)
        timer = DispatchWorkItem(block: { [weak self] in
            self?.isWaitingToConnect = false
            self?.handle(WalletConnectServiceError.timeout)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timer!)
    }

    private func handle(_ error: Error, for action: WalletConnectAction? = nil, delay: TimeInterval = 0) {
        canEstablishNewSessionPublisher.send(true)
        if let wcError = error as? WalletConnectServiceError {
            switch wcError {
            case .cancelled, .deallocated:
                return
            default:
                break
            }
        }

        if error.toTangemSdkError().isUserCancelled {
            return
        }

        AppLog.shared.error(error: error, params: action.map { [.walletConnectAction: $0.rawValue] } ?? [:])

        if let wcError = error as? WalletConnectServiceError, case .switchChainNotSupported = wcError {
            return
        }

        AppPresenter.shared.show(WalletConnectUIBuilder.makeErrorAlert(error), delay: delay)
    }

    private func resetSessionConnectTimer() {
        timer?.cancel()
        isWaitingToConnect = false
    }
}

extension WalletConnectV1Service: WalletConnectHandlerDataSource {
    func session(for request: Request) -> WalletConnectSession? {
        sessions.first(where: { $0.session.url.topic == request.url.topic })
    }

    func updateSession(_ session: WalletConnectSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            save()
        }
    }
}

extension WalletConnectV1Service: WalletConnectHandlerDelegate {
    func send(_ response: Response, for action: WalletConnectAction) {
        server.send(response)
    }

    func sendInvalid(_ request: Request) {
        server.send(.invalid(request))
    }

    func sendReject(for request: Request, with error: Error, for action: WalletConnectAction) {
        handle(error, for: action)
        server.send(.reject(request))
    }

    func sendUpdate(for session: Session, with walletInfo: Session.WalletInfo) {
        do {
            try server.updateSession(session, with: walletInfo)
        } catch {
            AppLog.shared.error(error)
        }
    }
}

extension WalletConnectV1Service {
    func containSession(for wallet: WalletInfo) -> Bool {
        sessions.contains(where: { $0.wallet == wallet })
    }
}

extension WalletConnectV1Service {
    func disconnectSession(with id: Int) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }

            let session = sessions[index]
            do {
                try server.disconnect(from: session.session)
            } catch {
                AppLog.shared.debug("Failed to disconnect WC session: \(error.localizedDescription)")
            }

            sessions.remove(at: index)
            save()
            Analytics.log(.sessionDisconnected)
        }
    }
}

extension WalletConnectV1Service: ServerDelegate {
    private var walletMeta: Session.ClientMeta {
        Session.ClientMeta(
            name: "Tangem Wallet",
            description: nil,
            icons: [],
            url: AppConstants.tangemDomainUrl
        )
    }

    private var rejectedResponse: Session.WalletInfo {
        Session.WalletInfo(
            approved: false,
            accounts: [],
            chainId: 0,
            peerId: "",
            peerMeta: walletMeta
        )
    }

    func server(_ server: Server, didFailToConnect url: WCURL) {
        handle(WalletConnectServiceError.failedToConnect)
        resetSessionConnectTimer()
    }

    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        let failureCompletion = { [unowned self] in
            canEstablishNewSessionPublisher.send(true)
            completion(rejectedResponse)
        }

        guard isWaitingToConnect else {
            failureCompletion()
            return
        }

        resetSessionConnectTimer()

        do {
            let walletInfo = try getWalletInfo(for: session.dAppInfo)
            askToConnect(walletInfo: walletInfo, dAppInfo: session.dAppInfo, server: server, completion: completion)
        } catch {
            handle(error, delay: 0.5)
            failureCompletion()
        }
    }

    private func getWalletInfo(for dAppInfo: Session.DAppInfo) throws -> WalletInfo {
        guard DApps().isSupported(dAppInfo.peerMeta.url) else {
            throw WalletConnectServiceError.unsupportedDApp
        }

        guard let blockchain = WalletConnectNetworkParserUtility.parse(
            dAppInfo: dAppInfo,
            isTestnet: AppEnvironment.current.isTestnet
        ) else {
            throw WalletConnectServiceError.unsupportedNetwork
        }

        let blockchainNetwork = cardModel.getBlockchainNetwork(for: blockchain, derivationPath: nil)

        let wallet = cardModel.walletModels
            .first { $0.blockchainNetwork == blockchainNetwork }
            .map { $0.wallet }

        guard let wallet = wallet else {
            throw WalletConnectServiceError.networkNotFound(name: blockchainNetwork.blockchain.displayName)
        }

        let derivedKey = wallet.publicKey.blockchainKey != wallet.publicKey.seedKey ? wallet.publicKey.blockchainKey : nil

        return WalletInfo(
            walletPublicKey: wallet.publicKey.seedKey,
            derivedPublicKey: derivedKey,
            derivationPath: wallet.publicKey.derivationPath,
            blockchain: blockchainNetwork.blockchain
        )
    }

    private func askToConnect(walletInfo: WalletInfo, dAppInfo: Session.DAppInfo, server: Server, completion: @escaping (Session.WalletInfo) -> Void) {
        wallet = walletInfo

        let peerMeta = dAppInfo.peerMeta
        let walletDescription = "\(walletInfo.blockchain.displayName) (\(AddressFormatter(address: walletInfo.address).truncated()))"
        var message = Localization.walletConnectRequestSessionStart(
            peerMeta.name,
            walletDescription,
            peerMeta.url.absoluteString
        )

        if let description = peerMeta.description, !description.isEmpty {
            message += "\n\n" + description
        }

        let isSelectedChainAvailable = walletInfo.blockchain.isEvm

        let onAccept = {
            self.sessions.filter {
                let savedUrl = $0.session.dAppInfo.peerMeta.url.host ?? ""
                let newUrl = dAppInfo.peerMeta.url.host ?? ""

                return $0.wallet == self.wallet &&
                    (savedUrl.count > newUrl.count ? savedUrl.contains(newUrl) : newUrl.contains(savedUrl))
            }.forEach { try? server.disconnect(from: $0.session) }
            completion(Session.WalletInfo(
                approved: true,
                accounts: [self.wallet!.address],
                chainId: self.wallet?.blockchain.chainId ?? 1, // binance case only?
                peerId: UUID().uuidString,
                peerMeta: self.walletMeta
            ))
        }

        let onSelectChain: (Wallet) -> Void = { wallet in
            let derivedKey = wallet.publicKey.blockchainKey != wallet.publicKey.seedKey ? wallet.publicKey.blockchainKey : nil

            self.wallet = WalletInfo(
                walletPublicKey: wallet.publicKey.seedKey,
                derivedPublicKey: derivedKey,
                derivationPath: wallet.publicKey.derivationPath,
                blockchain: wallet.blockchain
            )

            onAccept()
        }

        let onReject = {
            completion(self.rejectedResponse)
            self.canEstablishNewSessionPublisher.send(true)
        }

        let onSelectChainRequested = { [cardModel] in
            let availableChains = cardModel.walletModels
                .filter { $0.blockchainNetwork.blockchain.isEvm }
                .map { $0.wallet }

            AppPresenter.shared.show(
                WalletConnectUIBuilder.makeChainsSheet(
                    availableChains,
                    onAcceptAction: onSelectChain,
                    onReject: onReject
                ),
                delay: 0.3
            )
        }

        AppPresenter.shared.show(
            WalletConnectUIBuilder.makeAlert(
                for: .establishSession,
                message: message,
                onAcceptAction: onAccept,
                onReject: onReject,
                extraTitle: isSelectedChainAvailable ? Localization.walletConnectSelectNetwork : nil,
                onExtra: onSelectChainRequested
            ),
            delay: 0.5
        )
    }

    func server(_ server: Server, didConnect session: Session) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            if let sessionIndex = sessions.firstIndex(where: { $0.session == session }) { // reconnect
                sessions[sessionIndex].status = .connected
            } else {
                if let wallet = wallet { // new session only if wallet exists
                    sessions.append(WalletConnectSession(wallet: wallet, session: session, status: .connected))
                    save()
                }
            }

            canEstablishNewSessionPublisher.send(true)
        }
    }

    func server(_ server: Server, didDisconnect session: Session) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            if let index = sessions.firstIndex(where: { $0.session == session }) {
                sessions.remove(at: index)
                save()
            }
        }
    }

    func server(_ server: Server, didUpdate session: Session) {
        // TODO: handle?
    }
}

private struct DApps {
    private let unsupportedList: [String] = ["dydx.exchange"]

    func isSupported(_ dAppURL: URL) -> Bool {
        for dApp in unsupportedList {
            if dAppURL.absoluteString.contains(dApp) {
                return false
            }
        }

        return true
    }
}

public typealias WalletConnectV1URI = WCURL
