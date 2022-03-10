//
//  WalletConnectService.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import TangemSdk
import BlockchainSdk
import CryptoSwift
import SwiftUI
import web3swift

protocol WalletConnectChecker: AnyObject {
    var isServiceBusy: CurrentValueSubject<Bool, Never> { get }
    func containSession(for wallet: WalletInfo) -> Bool
}

protocol WalletConnectSessionController: WalletConnectChecker {
    var sessionsPublisher: Published<[WalletConnectSession]>.Publisher { get }
    func disconnectSession(at index: Int)
    func canHandle(url: String) -> Bool
    func handle(url: String) -> Bool
}

protocol WalletConnectHandlerDelegate: AnyObject {
    func send(_ response: Response, for action: WalletConnectAction)
    func sendInvalid(_ request: Request)
    func sendReject(for request: Request, with error: Error, for action: WalletConnectAction)
}

protocol WalletConnectHandlerDataSource: AnyObject {
    var server: Server! { get }
    func session(for request: Request, address: String) -> WalletConnectSession?
}

enum WalletConnectAction: String {
    case personalSign = "personal_sign"
    case signTransaction = "eth_signTransaction"
    case sendTransaction = "eth_sendTransaction"
    case bnbSign = "bnb_sign"
    case bnbTxConfirmation = "bnb_tx_confirmation"
    case signTypedData = "eth_signTypedData"
    
//    var shouldDisplaySuccessAlert: Bool {
//        switch self {
//        case .bnbTxConfirmation: return false
//        default: return true
//        }
//    }
    
    var successMessage: String {
        switch self {
        case .personalSign, .signTypedData: return "wallet_connect_message_signed".localized
        case .signTransaction: return "wallet_connect_transaction_signed".localized
        case .sendTransaction: return "wallet_connect_transaction_signed_and_send".localized
        case .bnbSign: return "wallet_connect_bnb_transaction_signed".localized
        case .bnbTxConfirmation: return "".localized
        }
    }
}

enum WalletConnectNetwork {
    case eth(chainId: Int), bnb(testnet: Bool)
    
    var blockchain: Blockchain? {
        switch self {
        case .eth(let chainId):
            let items = SupportedTokenItems()
            let allBlockchains = items.blockchains(for: [.secp256k1], isTestnet: nil)
            return allBlockchains.first(where: { $0.chainId == chainId })
        case .bnb(let testnet):
            return .binance(testnet: testnet)
        }
    }
    
    var chainId: Int? {
        switch self {
        case .eth(let chainId):
            return chainId
        case .bnb:
            return nil
        }
    }
}

class WalletConnectService: ObservableObject {
    var isServiceBusy: CurrentValueSubject<Bool, Never> = .init(false)
    
    @Published private(set) var sessions: [WalletConnectSession] = .init()
    var sessionsPublisher: Published<[WalletConnectSession]>.Publisher { $sessions }
    
    private(set) var server: Server!
    
    fileprivate var wallet: WalletInfo? = nil
    private let sessionsKey = "wc_sessions"
    
    private unowned var cardScanner: WalletConnectCardScanner
    private var bag: Set<AnyCancellable> = []
    private var isWaitingToConnect: Bool = false
    private var timer: DispatchWorkItem?
    private let updateQueue = DispatchQueue(label: "ws_sessions_update_queue")
    
    init(assembly: Assembly, cardScanner: WalletConnectCardScanner, signer: TangemSigner, scannedCardsRepository: ScannedCardsRepository) {
        self.cardScanner = cardScanner
        server = Server(delegate: self)
        server.register(handler: PersonalSignHandler(signer: signer, delegate: self, dataSource: self))
        server.register(handler: SignTransactionHandler(signer: signer, delegate: self, dataSource: self, assembly: assembly, scannedCardsRepo: scannedCardsRepository))
        server.register(handler: SendTransactionHandler(signer: signer, delegate: self, dataSource: self, assembly: assembly, scannedCardsRepo: scannedCardsRepository))
        server.register(handler: BnbSignHandler(signer: signer, delegate: self, dataSource: self))
        server.register(handler: BnbSuccessHandler(delegate: self, dataSource: self))
        server.register(handler: SignTypedDataHandler(signer: signer, delegate: self, dataSource: self))
    }
    
    func disconnect(from session: Session) {
        do {
            if let session = sessions.first(where: { $0.session == session }) {
                try server.disconnect(from: session.session)
            }
        } catch {
            handle(WalletConnectServiceError.other(error))
        }
    }
    
    func restore() {
        updateQueue.sync {
            let decoder = JSONDecoder()
            if let oldSessionsObject = UserDefaults.standard.object(forKey: self.sessionsKey) as? Data {
                DispatchQueue.main.async {
                    self.sessions = (try? decoder.decode([WalletConnectSession].self, from: oldSessionsObject)) ?? []
                    self.sessions.forEach {
                        do {
                            try self.server.reconnect(to: $0.session)
                        } catch {
                            self.handle(WalletConnectServiceError.other(error))
                        }
                    }
                }
                
            }
        }
    }
    
    private func connect(to url: WCURL) {
        setupSessionConnectTimer()
        do {
            try server.connect(to: url)
        } catch {
            print(error)
            resetSessionConnectTimer()
            handle(error)
            isServiceBusy.send(false)
        }
    }
    
    private func save() {
        updateQueue.sync {
            let encoder = JSONEncoder()
            if let sessionsData = try? encoder.encode(self.sessions) {
                UserDefaults.standard.set(sessionsData, forKey: self.sessionsKey)
            }
        }
    }
    
    private func setupSessionConnectTimer() {
        isWaitingToConnect = true
        isServiceBusy.send(true)
        timer = DispatchWorkItem(block: { [unowned self] in
            self.isWaitingToConnect = false
            self.handle(WalletConnectServiceError.timeout)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timer!)
    }
    
    private func handle(_ error: Error, for action: WalletConnectAction? = nil, delay: TimeInterval = 0) {
        isServiceBusy.send(false)
        if let wcError = error as? WalletConnectServiceError {
            switch wcError {
            case .cancelled, .deallocated:
                return
            default:
                break
            }
        }
        
        if let tangemError = error as? TangemSdkError, case .userCancelled = tangemError {
            return
        }
        
        Analytics.logWcEvent(.error(error, action))
        presentOnTop(WalletConnectUIBuilder.makeErrorAlert(error), delay: delay)
    }
    
    private func resetSessionConnectTimer() {
        timer?.cancel()
        isWaitingToConnect = false
    }
    
    private func presentOnTop(_ vc: UIViewController, delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(vc)
        }
    }
}

extension WalletConnectService: WalletConnectHandlerDataSource {
    func session(for request: Request, address: String) -> WalletConnectSession? {
        sessions.first(where: { $0.wallet.address.lowercased() == address.lowercased() && $0.session.url.topic == request.url.topic })
    }
}

extension WalletConnectService: WalletConnectHandlerDelegate {
    func send(_ response: Response, for action: WalletConnectAction) {
        server.send(response)
        Analytics.logWcEvent(.action(action))
        
//        if action.shouldDisplaySuccessAlert {
//            presentOnTop(WalletConnectUIBuilder.makeAlert(for: .success, message: action.successMessage), delay: 0.5)
//        }
    }
    
    func sendInvalid(_ request: Request) {
        Analytics.logWcEvent(.invalidRequest(json: request.jsonString))
        server.send(.invalid(request))
    }
    
    func sendReject(for request: Request, with error: Error, for action: WalletConnectAction) {
        handle(error, for: action)
        server.send(.reject(request))
    }
}

extension WalletConnectService: WalletConnectChecker {
    func containSession(for wallet: WalletInfo) -> Bool {
        sessions.contains(where: { $0.wallet == wallet })
    }
}

extension WalletConnectService: WalletConnectSessionController {
    func disconnectSession(at index: Int) {
        guard index < sessions.count else { return }
        
        let session = sessions[index]
        do {
            try server.disconnect(from: session.session)
        } catch {
            print(error)
        }
        
        sessions.remove(at: index)
        save()
        Analytics.logWcEvent(.session(.disconnect, session.session.dAppInfo.peerMeta.url))
    }
    
    func canHandle(url: String) -> Bool {
        WCURL(url) != nil
    }
}

extension WalletConnectService: ServerDelegate {
    private var walletMeta: Session.ClientMeta {
        Session.ClientMeta(name: "Tangem Wallet",
                           description: nil,
                           icons: [],
                           url: Constants.tangemDomainUrl)
    }
    
    private var rejectedResponse: Session.WalletInfo {
        Session.WalletInfo(approved: false,
                           accounts: [],
                           chainId: 0,
                           peerId: "",
                           peerMeta: walletMeta)
    }
    
    func server(_ server: Server, didFailToConnect url: WCURL) {
        handle(WalletConnectServiceError.failedToConnect)
        resetSessionConnectTimer()
    }
    
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        let failureCompletion = { [unowned self] in
            self.isServiceBusy.send(false)
            completion(self.rejectedResponse)
        }
        
        guard isWaitingToConnect else {
            failureCompletion()
            return
        }
        
        resetSessionConnectTimer()
        guard let parsedNetworkInfo = WalletConnectNetworkParserUtility.parse(dAppInfo: session.dAppInfo) else {
            failureCompletion()
            return
        }
        let chainId = parsedNetworkInfo.chainId
        
        cardScanner.scanCard(for: parsedNetworkInfo.network)
            .sink { [unowned self] completion in
                if case let .failure(error) = completion {
                    self.handle(error, delay: 0.5)
                    failureCompletion()
                }
            } receiveValue: { [unowned self] wallet in
                self.wallet = wallet
                
                let peerMeta = session.dAppInfo.peerMeta
                var message = String(format: "wallet_connect_request_session_start".localized, wallet.cid, peerMeta.name, peerMeta.url.absoluteString)
                if let description = peerMeta.description, !description.isEmpty {
                    message += "\n\n" + description
                }
                let onAccept = {
                    self.sessions.filter {
                        let savedUrl = $0.session.dAppInfo.peerMeta.url.host ?? ""
                        let newUrl = session.dAppInfo.peerMeta.url.host ?? ""
                        
                        return $0.wallet == wallet &&
                            $0.wallet.chainId == chainId &&
                            (savedUrl.count > newUrl.count ? savedUrl.contains(newUrl) : newUrl.contains(savedUrl))
                    }.forEach { try? server.disconnect(from: $0.session) }
                    completion(Session.WalletInfo(approved: true,
                                                  accounts: [wallet.address],
                                                  chainId: wallet.chainId ?? 1,
                                                  peerId: UUID().uuidString,
                                                  peerMeta: self.walletMeta))
                }
                
                self.presentOnTop(WalletConnectUIBuilder.makeAlert(for: .establishSession,
                                                              message: message,
                                                              onAcceptAction: onAccept,
                                                              onReject: {
                                                                completion(self.rejectedResponse)
                                                                self.isServiceBusy.send(false)
                                                              }),
                             delay: 0.5)
            }
            .store(in: &bag)
    }
    
    func server(_ server: Server, didConnect session: Session) {
        if let sessionIndex = sessions.firstIndex(where: { $0.session == session }) { //reconnect
            sessions[sessionIndex].status = .connected
        } else {
            if let wallet = self.wallet { //new session only if wallet exists
                sessions.append(WalletConnectSession(wallet: wallet, session: session, status: .connected))
                save()
                Analytics.logWcEvent(.session(.connect, session.dAppInfo.peerMeta.url))
            }
        }
        isServiceBusy.send(false)
    }
    
    func server(_ server: Server, didDisconnect session: Session) {
        if let index = sessions.firstIndex(where: { $0.session == session }) {
            sessions.remove(at: index)
            save()
        }
    }
    
    func server(_ server: Server, didUpdate session: Session) {
        //todo: handle?
    }
}

extension WalletConnectService: URLHandler {
    func handle(url: URL) -> Bool {
        guard let extracted = extractWcUrl(from: url) else { return false }
        
        guard let wcUrl = WCURL(extracted.url) else { return false }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + extracted.handleDelay) {
            self.connect(to: wcUrl)
        }
        
        return true
    }
    
    func handle(url: String) -> Bool {
        guard let url = URL(string: url) else { return false }
        
        return handle(url: url)
    }
    
    private func extractWcUrl(from url: URL) -> ExtractedWCUrl? {
        let absoluteStr = url.absoluteString
        if canHandle(url: absoluteStr) {
            return (url: absoluteStr, handleDelay: 0)
        }
        
        let uriPrefix = "uri="
        let wcPrefix = "wc:"
        
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let scheme = components.scheme,
            var query = components.query
        else { return nil }
        
        guard query.starts(with: uriPrefix + wcPrefix) ||
                ((Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String:Any]])?.map { $0["CFBundleURLSchemes"] as? [String] }.contains(where: { $0?.contains(scheme) ?? false }) ?? false)
        else { return nil }
        
        query.removeFirst(uriPrefix.count)

        guard canHandle(url: query) else { return nil }
        
        return (query, 0.5)
    }
}

enum WalletConnectServiceError: LocalizedError {
    case failedToConnect
    case signFailed
    case cancelled
    case timeout
    case deallocated
    case failedToFindSigner
    case cardNotFound
    case sessionNotFound
    case txNotFound
    case failedToBuildTx(code: TxErrorCodes)
    case other(Error)
    case noChainId
    case unsupportedNetwork
    var shouldHandle: Bool {
        switch self {
        case .cancelled, .deallocated, .failedToFindSigner: return false
        default: return true
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .timeout: return "wallet_connect_error_timeout".localized
        case .signFailed: return "wallet_connect_error_sing_failed".localized
        case .failedToConnect: return "wallet_connect_error_failed_to_connect".localized
        case .cardNotFound: return "wallet_connect_card_not_found".localized
        case .txNotFound: return "wallet_connect_tx_not_found".localized
        case .sessionNotFound: return "wallet_connect_session_not_found".localized
        case .failedToBuildTx(let code): return String(format: "wallet_connect_failed_to_build_tx".localized, code.rawValue)
        case .other(let error): return error.localizedDescription
        case .noChainId: return "wallet_connect_service_no_chain_id".localized
        case .unsupportedNetwork: return "wallet_connect_scanner_error_unsupported_network".localized
        default: return ""
        }
    }
}

fileprivate typealias ExtractedWCUrl = (url: String, handleDelay: TimeInterval)

extension WalletConnectServiceError {
    enum TxErrorCodes: String {
        case noWalletManager
        case wrongAddress
        case noValue
    }
}
