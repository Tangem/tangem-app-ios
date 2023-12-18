//
//  ExpressProvidersSelectorViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

final class ExpressProvidersSelectorViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var providerViewModels: [ProviderRowViewModel] = []

    // MARK: - Dependencies

    private var allProviders: [ExpressAvailableProvider] = []
    private var selectedProvider: ExpressAvailableProvider?

    private let percentFormatter: PercentFormatter
    private let expressProviderFormatter: ExpressProviderFormatter
    private let expressRepository: ExpressRepository
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressProvidersSelectorRoutable

    private var stateSubscription: AnyCancellable?

    init(
        percentFormatter: PercentFormatter,
        expressProviderFormatter: ExpressProviderFormatter,
        expressRepository: ExpressRepository,
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersSelectorRoutable
    ) {
        self.percentFormatter = percentFormatter
        self.expressProviderFormatter = expressProviderFormatter
        self.expressRepository = expressRepository
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        bind()
        initialSetup()
    }

    func bind() {
        stateSubscription = expressInteractor.state
            .dropFirst()
            .compactMap { $0.quote }
            .removeDuplicates()
            .sink { [weak self] state in
                self?.updateView()
            }
    }

    func initialSetup() {
        runTask(in: self) { viewModel in
            try await viewModel.updateFields()
            await viewModel.setupProviderRowViewModels()
        }
    }

    func updateView() {
        runTask(in: self) { viewModel in
            await viewModel.setupProviderRowViewModels()
        }
    }

    func updateFields() async throws {
        allProviders = await expressInteractor.getAllProviders()
        selectedProvider = await expressInteractor.getSelectedProvider()
    }

    func setupProviderRowViewModels() async {
        let viewModels: [ProviderRowViewModel] = await allProviders
            .asyncSorted(sort: >, by: { await $0.getPriority() })
            .asyncCompactMap { provider in
                if !provider.isAvailable {
                    return unavailableProviderRowViewModel(provider: provider.provider)
                }

                if await provider.getState().isAvailableToShow {
                    return await mapToProviderRowViewModel(provider: provider)
                }

                return nil
            }

        await runOnMain {
            providerViewModels = viewModels
        }
    }

    func mapToProviderRowViewModel(provider: ExpressAvailableProvider) async -> ProviderRowViewModel {
        let senderCurrencyCode = expressInteractor.getSender().tokenItem.currencySymbol
        let destinationCurrencyCode = expressInteractor.getDestination()?.tokenItem.currencySymbol
        var subtitles: [ProviderRowViewModel.Subtitle] = []

        let state = await provider.getState()
        subtitles.append(
            expressProviderFormatter.mapToRateSubtitle(
                state: state,
                senderCurrencyCode: senderCurrencyCode,
                destinationCurrencyCode: destinationCurrencyCode,
                option: .exchangeReceivedAmount
            )
        )

        let isSelected = selectedProvider?.provider.id == provider.provider.id
        let badge: ProviderRowViewModel.Badge? = state.isPermissionRequired ? .permissionNeeded : .none

        if let percentSubtitle = await makePercentSubtitle(provider: provider) {
            subtitles.append(percentSubtitle)
        }

        return ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider.provider),
            isDisabled: false,
            badge: badge,
            subtitles: subtitles,
            detailsType: isSelected ? .selected : .none,
            tapAction: { [weak self] in
                self?.userDidTap(provider: provider)
            }
        )
    }

    func unavailableProviderRowViewModel(provider: ExpressProvider) -> ProviderRowViewModel {
        ProviderRowViewModel(
            provider: expressProviderFormatter.mapToProvider(provider: provider),
            isDisabled: true,
            badge: .none,
            subtitles: [.text(Localization.expressProviderNotAvailable)],
            detailsType: .none,
            tapAction: {}
        )
    }

    func userDidTap(provider: ExpressAvailableProvider) {
        // Cancel subscription that view do not jump
        stateSubscription?.cancel()
        Analytics.log(event: .swapProviderChosen, params: [.provider: provider.provider.name])
        expressInteractor.updateProvider(provider: provider)
        coordinator.closeExpressProvidersSelector()
    }

    func makePercentSubtitle(provider: ExpressAvailableProvider) async -> ProviderRowViewModel.Subtitle? {
        // For best we don't add percent badge
        guard !provider.isBest else {
            return nil
        }

        guard let quote = await provider.getState().quote,
              let bestRate = await allProviders.first(where: { $0.isBest })?.getState().quote?.rate else {
            return nil
        }

        let changePercent = 1 - quote.rate / bestRate
        let formatted = percentFormatter.expressRatePercentFormat(value: changePercent)

        return .percent(formatted, signType: ChangeSignType(from: changePercent))
    }
}

private extension ExpressProviderManagerState {
    var isPermissionRequired: Bool {
        switch self {
        case .permissionRequired:
            return true
        default:
            return false
        }
    }

    var isAvailableToShow: Bool {
        switch self {
        case .error:
            return false
        default:
            return true
        }
    }
}
