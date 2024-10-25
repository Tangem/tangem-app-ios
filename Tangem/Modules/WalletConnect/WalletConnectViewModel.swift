//
//  WalletConnectViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 22.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import AVFoundation

class WalletConnectViewModel: ObservableObject {
    @Injected(\.walletConnectService) private var walletConnectService: WalletConnectService

    @Published var isActionSheetVisible: Bool = false
    @Published var showCameraDeniedAlert: Bool = false
    @Published var alert: AlertBinder?
    @Published var isServiceBusy: Bool = true

    @Published @MainActor var sessions: [WalletConnectSavedSession] = []

    @MainActor
    var noActiveSessions: Bool { sessions.isEmpty }

    private let disabledLocalizedReason: String?
    private var bag = Set<AnyCancellable>()
    private var pendingURI: WalletConnectRequestURI?
    private var scannedQRCode: CurrentValueSubject<String?, Never> = .init(nil)

    private weak var coordinator: WalletConnectRoutable?

    init(disabledLocalizedReason: String?, coordinator: WalletConnectRoutable) {
        self.disabledLocalizedReason = disabledLocalizedReason
        self.coordinator = coordinator
    }

    deinit {
        AppLog.shared.debug("WalletConnectViewModel deinit")
    }

    func onAppear() {
        Analytics.log(.walletConnectScreenOpened)
        bind()
    }

    func disconnectSession(_ session: WalletConnectSavedSession) {
        Analytics.log(.buttonStopWalletConnectSession)
        Task { [weak self] in
            await self?.walletConnectService.disconnectSession(with: session.id)
            await runOnMain {
                withAnimation {
                    self?.objectWillChange.send()
                }
            }
        }
    }

    func readFromClipboard() throws -> WalletConnectRequestURI? {
        guard let pasteboardValue = UIPasteboard.general.string else {
            return nil
        }

        return try WalletConnectURLParser().parse(uriString: pasteboardValue)
    }

    func pasteFromClipboard() {
        guard let pendingURI else { return }

        openSession(with: pendingURI)
        self.pendingURI = nil
    }

    func openSession() {
        Analytics.log(.buttonStartWalletConnectSession)

        if let disabledLocalizedReason {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        do {
            let pending = try readFromClipboard()
        } catch {
            makeAlert(with: error.localizedDescription)
            return
        }

        if pendingURI != nil {
            isActionSheetVisible = true
        } else {
            openQRScanner()
        }
    }

    private func openSession(with uri: WalletConnectRequestURI) {
        Analytics.debugLog(eventInfo: Analytics.WalletConnectDebugEvent.attemptingToOpenSession(url: uri.debugString))
        walletConnectService.openSession(with: uri)
    }

    private func bind() {
        bag.removeAll()

        subscribeToNewSessions()

        walletConnectService.canEstablishNewSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canEstablishNewSession in
                self?.isServiceBusy = !canEstablishNewSession
            }
            .store(in: &bag)

        scannedQRCode
            .compactMap { $0 }
            .compactMap { [weak self] in
                self?.parseURI($0)
            }
            .sink { [weak self] uri in
                self?.openSession(with: uri)
            }
            .store(in: &bag)
    }

    func parseURI(_ uri: String) -> WalletConnectRequestURI? {
        do {
            let uri = try WalletConnectURLParser().parse(uriString: uri)
            return uri
        } catch {
            makeAlert(with: error.localizedDescription)
            return nil
        }
    }

    func makeAlert(with message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.alert = AlertBuilder.makeOkErrorAlert(message: message)
        }
    }

    private func subscribeToNewSessions() {
        Task {
            for await sessions in await walletConnectService.newSessions {
                AppLog.shared.debug("Loaded v2 sessions: \(sessions)")
                await MainActor.run {
                    withAnimation {
                        self.sessions = sessions
                    }
                }
            }
        }
    }
}

// MARK: - Navigation

extension WalletConnectViewModel {
    func openQRScanner() {
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            showCameraDeniedAlert = true
        } else {
            let binding = Binding<String>(
                get: { [weak self] in
                    self?.scannedQRCode.value ?? ""
                },
                set: { [weak self] in
                    self?.scannedQRCode.send($0)
                }
            )

            coordinator?.openQRScanner(with: binding)
        }
    }
}
