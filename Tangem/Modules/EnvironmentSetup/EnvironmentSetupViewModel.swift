//
//  EnvironmentSetupViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class EnvironmentSetupViewModel: ObservableObject {
    @Injected(\.promotionService) var promotionService: PromotionServiceProtocol

    // MARK: - ViewState

    @Published var appSettingsTogglesViewModels: [DefaultToggleRowViewModel] = []
    @Published var featureStateViewModels: [FeatureStateRowViewModel] = []
    @Published var additionalSettingsViewModels: [DefaultRowViewModel] = []
    @Published var alert: AlertBinder?

    // Promotion
    @Published var currentPromoCode: String = ""
    @Published var finishedPromotionNames: String = ""
    @Published var awardedPromotionNames: String = ""

    // MARK: - Dependencies

    private let featureStorage = FeatureStorage()
    private unowned let coordinator: EnvironmentSetupRoutable
    private var bag: Set<AnyCancellable> = []

    init(coordinator: EnvironmentSetupRoutable) {
        self.coordinator = coordinator

        setupView()
    }

    func setupView() {
        appSettingsTogglesViewModels = [
            DefaultToggleRowViewModel(
                title: "Use testnet",
                isOn: BindingValue<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.isTestnet },
                    set: { $0.isTestnet = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Use dev API",
                isOn: BindingValue<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.useDevApi },
                    set: { $0.useDevApi = $1 }
                )
            ),
            DefaultToggleRowViewModel(
                title: "Use fake tx history",
                isOn: BindingValue<Bool>(
                    root: featureStorage,
                    default: false,
                    get: { $0.useFakeTxHistory },
                    set: { $0.useFakeTxHistory = $1 }
                )
            ),
        ]

        featureStateViewModels = Feature.allCases.reversed().map { feature in
            FeatureStateRowViewModel(
                feature: feature,
                enabledByDefault: FeatureProvider.isAvailableForReleaseVersion(feature),
                state: BindingValue<FeatureState>(
                    root: featureStorage,
                    default: .default,
                    get: { $0.availableFeatures[feature] ?? .default },
                    set: { obj, state in
                        switch state {
                        case .default:
                            obj.availableFeatures.removeValue(forKey: feature)
                        case .on, .off:
                            obj.availableFeatures[feature] = state
                        }
                    }
                )
            )
        }

        additionalSettingsViewModels = [
            DefaultRowViewModel(title: "Supported Blockchains") { [weak self] in
                self?.coordinator.openSupportedBlockchainsPreferences()
            },
        ]

        updateCurrentPromoCode()

        updateFinishedPromotionNames()

        updateAwardedPromotionNames()
    }

    func copyCurrentPromoCode() {
        guard let promoCode = promotionService.promoCode else { return }

        UIPasteboard.general.string = promoCode

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func resetCurrentPromoCode() {
        promotionService.setPromoCode(nil)
        updateCurrentPromoCode()
    }

    func resetFinishedPromotionNames() {
        promotionService.resetFinishedPromotions()
        updateFinishedPromotionNames()
    }

    func resetAward() {
        // TODO: We can't pass cardId, only userWaleltId. Obtain cardId from scan or refactor to userWaleltId
//        runTask { [weak self] in
//            guard let self else { return }
//
//            let success = (try? await promotionService.resetAward(cardId: cardId)) != nil
//
//            DispatchQueue.main.async {
//                let feedbackGenerator = UINotificationFeedbackGenerator()
//                feedbackGenerator.notificationOccurred(success ? .success : .error)
//
//                self.updateAwardedPromotionNames()
//            }
//        }
    }

    func showExitAlert() {
        let alert = Alert(
            title: Text("Are you sure you want to exit the app?"),
            primaryButton: .destructive(Text("Exit"), action: { exit(1) }),
            secondaryButton: .cancel()
        )
        self.alert = AlertBinder(alert: alert)
    }

    private func updateCurrentPromoCode() {
        currentPromoCode = promotionService.promoCode ?? "[none]"
    }

    private func updateFinishedPromotionNames() {
        let finishedPromotionNames = promotionService.finishedPromotionNames()
        if finishedPromotionNames.isEmpty {
            self.finishedPromotionNames = "[none]"
        } else {
            self.finishedPromotionNames = promotionService.finishedPromotionNames().joined(separator: ", ")
        }
    }

    private func updateAwardedPromotionNames() {
        let awardedPromotionNames = promotionService.awardedPromotionNames()
        if awardedPromotionNames.isEmpty {
            self.awardedPromotionNames = "[none]"
        } else {
            self.awardedPromotionNames = awardedPromotionNames.joined(separator: ", ")
        }
    }
}
