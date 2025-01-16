//
//  VisaOnboardingWalletConnectViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 15/01/25.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemVisa
import TangemFoundation

class VisaOnboardingWalletConnectViewModel: ObservableObject {
    @Injected(\.safariManager) private var safariManager: SafariManager

    private var delegate: VisaOnboardingInProgressDelegate?
    private var safariHandle: SafariHandle?

    private let statusUpdateTimeIntervalSec: TimeInterval = 15

    private var scheduler = AsyncTaskScheduler()

    init(delegate: VisaOnboardingInProgressDelegate? = nil) {
        self.delegate = delegate
    }

    func openBrowser() {
        let visaURL = VisaUtilities().walletConnectURL
        safariHandle = safariManager.openURL(visaURL) { [weak self] successURL in
            self?.safariHandle = nil
            self?.proceedOnboardingIfPossible()
        }
    }

    func openShareSheet() {
        let visaURL = VisaUtilities().walletConnectURL
        // TODO: Replace with ShareLinks https://developer.apple.com/documentation/swiftui/sharelink for iOS 16+
        let av = UIActivityViewController(activityItems: [visaURL], applicationActivities: nil)
        AppPresenter.shared.show(av)
        setupStatusUpdateTask()
    }
    
    func cancelStatusUpdates() {
        scheduler.cancel()
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[VisaOnboardingWalletConnectViewModel] - \(message())")
    }

    private func setupStatusUpdateTask() {
        scheduler.scheduleJob(interval: statusUpdateTimeIntervalSec, repeats: true) { [weak self] in
            do {
                guard try await self?.delegate?.canProceedOnboarding() ?? false else {
                    return
                }

                await self?.proceedOnboarding()
            } catch {
                self?.log("Failed to check if onboarding can proceed: \(error)")
            }
        }
    }

    private func proceedOnboardingIfPossible() {
        runTask(in: self, isDetached: false) { viewModel in
            do {
                if try await viewModel.delegate?.canProceedOnboarding() ?? false {
                    await viewModel.proceedOnboarding()
                    return
                }
            } catch {
                viewModel.log("Failed to check if onboarding can proceed: \(error)")
            }

            viewModel.setupStatusUpdateTask()
        }
    }

    @MainActor
    private func proceedOnboarding() async {
        cancelStatusUpdates()
        await delegate?.proceedFromCurrentRemoteState()
    }
}
