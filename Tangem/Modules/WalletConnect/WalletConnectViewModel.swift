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
    @Published var v1Sessions: [WalletConnectSession] = []

    @Published @MainActor var v2Sessions: [WalletConnectSavedSession] = []

    @MainActor
    var noActiveSessions: Bool {
        v1Sessions.isEmpty && v2Sessions.isEmpty
    }

    private var cardModel: CardViewModel
    private var bag = Set<AnyCancellable>()
    private var pendingURI: WalletConnectRequestURI?
    private var scannedQRCode: CurrentValueSubject<String?, Never> = .init(nil)

    private unowned let coordinator: WalletConnectRoutable

    init(cardModel: CardViewModel, coordinator: WalletConnectRoutable) {
        self.cardModel = cardModel
        self.coordinator = coordinator
    }

    deinit {
        AppLog.shared.debug("WalletConnectViewModel deinit")
    }

    func onAppear() {
        Analytics.log(.walletConnectScreenOpened)
        bind()
    }

    func disconnectV1Session(_ session: WalletConnectSession) {
        Analytics.log(.buttonStopWalletConnectSession)
        walletConnectService.disconnectSession(with: session.id)
        withAnimation {
            self.objectWillChange.send()
        }
    }

    func disconnectV2Session(_ session: WalletConnectSavedSession) {
        Analytics.log(.buttonStopWalletConnectSession)
        Task { [weak self] in
            await self?.walletConnectService.disconnectV2Session(with: session.id)
            await runOnMain {
                withAnimation {
                    self?.objectWillChange.send()
                }
            }
        }
    }

    func tryReadFromClipboard() -> WalletConnectRequestURI? {
        guard let pasteboardValue = UIPasteboard.general.string,
              let uri = WalletConnectURLParser().parse(pasteboardValue),
              walletConnectService.canOpenSession(with: uri) else {
            return nil
        }

        return uri
    }

    func pasteFromClipboard() {
        guard let pendingURI else { return }

        openSession(with: pendingURI)
        self.pendingURI = nil
    }

    func openSession() {
        Analytics.log(.buttonStartWalletConnectSession)

        if let disabledLocalizedReason = cardModel.getDisabledLocalizedReason(for: .walletConnect) {
            alert = AlertBuilder.makeDemoAlert(disabledLocalizedReason)
            return
        }

        pendingURI = tryReadFromClipboard()

        if pendingURI != nil {
            isActionSheetVisible = true
        } else {
            openQRScanner()
        }
    }

    private func openSession(with uri: WalletConnectRequestURI) {
        guard walletConnectService.canOpenSession(with: uri) else {
            alert = WalletConnectServiceError.failedToConnect.alertBinder
            return
        }

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

        walletConnectService.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                guard let self = self else { return }

                v1Sessions = $0
                AppLog.shared.debug("Loaded v1 sessions: \($0)")
            })
            .store(in: &bag)

        scannedQRCode
            .compactMap { $0 }
            .compactMap { WalletConnectURLParser().parse($0) }
            .sink { [weak self] uri in
                self?.openSession(with: uri)
            }
            .store(in: &bag)
    }

    private func subscribeToNewSessions() {
        Task {
            for await sessions in await walletConnectService.newSessions {
                AppLog.shared.debug("Loaded v2 sessions: \(sessions)")
                await MainActor.run {
                    withAnimation {
                        self.v2Sessions = sessions
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

            coordinator.openQRScanner(with: binding)
        }
    }
}
