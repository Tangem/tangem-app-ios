//
//  TokenMarketsDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class TokenMarketsDetailsViewModel: ObservableObject {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    @Published var price: String
    @Published var priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .neutral
    @Published var shortDescription: String?
    @Published var fullDescription: String?
    @Published var selectedPriceChangeIntervalType = MarketsPriceIntervalType.day
    @Published var isLoading = true
    @Published var alert: AlertBinder?

    // MARK: Blocks

    @Published var insightsViewModel: MarketsTokenDetailsInsightsViewModel?
    @Published var metricsViewModel: MarketsTokenDetailsMetricsViewModel?
    @Published var pricePerformanceViewModel: MarketsTokenDetailsPricePerformanceViewModel?
    @Published var linksSections: [TokenMarketsDetailsLinkSection] = []
    @Published var portfolioViewModel: MarketsPortfolioContainerViewModel?
    @Published private(set) var historyChartViewModel: MarketsHistoryChartViewModel?

    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

    let priceChangeIntervalOptions = MarketsPriceIntervalType.allCases

    var priceChangeState: TokenPriceChangeView.State {
        guard let pickedDate else {
            let changePercent = loadedPriceChangeInfo[selectedPriceChangeIntervalType.rawValue]
            return priceChangeUtility.convertToPriceChangeState(changePercent: changePercent)
        }

        // TODO: calculate from interval between picked date and now
        print("Price change state for picked date: \(pickedDate)")
        return .noData
    }

    var tokenName: String {
        tokenInfo.name
    }

    var priceDate: String {
        guard let pickedDate else {
            return Localization.commonToday
        }

        return "\(dateFormatter.string(from: pickedDate)) – \(Localization.commonNow)"
    }

    var pickedDate: Date? {
        guard let pickedTimeInterval else {
            return nil
        }

        return Date(timeIntervalSince1970: pickedTimeInterval)
    }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    @Published private var pickedTimeInterval: TimeInterval?
    @Published private var loadedHistoryInfo: [TimeInterval: Decimal] = [:]
    @Published private var loadedPriceChangeInfo: [String: Decimal] = [:]
    @Published private var currentPriceSubject: CurrentValueSubject<Decimal, Never>

    private weak var coordinator: TokenMarketsDetailsRoutable?

    private let balanceFormatter = BalanceFormatter()
    private let priceChangeUtility = PriceChangeUtility()
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:MM"
        return dateFormatter
    }()

    private let fiatBalanceFormattingOptions: BalanceFormattingOptions = .init(
        minFractionDigits: 2,
        maxFractionDigits: 8,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .defaultFiat(roundingMode: .bankers)
    )
    private let quotesUpdateTimeInterval: TimeInterval = 60.0

    private let tokenInfo: MarketsTokenModel
    private let dataProvider: MarketsTokenDetailsDataProvider
    private let walletDataProvider = MarketsWalletDataProvider()

    private var quotesUpdateScheduler: AsyncTaskScheduler?
    private var loadedInfo: TokenMarketsDetailsModel?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(tokenInfo: MarketsTokenModel, dataProvider: MarketsTokenDetailsDataProvider, coordinator: TokenMarketsDetailsRoutable?) {
        currentPriceSubject = .init(tokenInfo.currentPrice ?? 0.0)
        self.tokenInfo = tokenInfo
        self.dataProvider = dataProvider
        self.coordinator = coordinator

        price = balanceFormatter.formatFiatBalance(
            tokenInfo.currentPrice,
            formattingOptions: fiatBalanceFormattingOptions
        )

        bind()
        loadedHistoryInfo = [Date().timeIntervalSince1970: tokenInfo.priceChangePercentage[MarketsPriceIntervalType.day.marketsListId] ?? 0]
        loadedPriceChangeInfo = tokenInfo.priceChangePercentage
        loadDetailedInfo()

        makePreloadBlocksViewModels()
        makeHistoryChartViewModel()
    }

    deinit {
        print("TokenMarketsDetailsViewModel deinit")
        quotesUpdateScheduler?.cancel()
        quotesUpdateScheduler = nil
    }

    // MARK: - Actions

    func openLinkAction(_ link: String) {
        guard let url = URL(string: link) else {
            log("Failed to create link from: \(link)")
            return
        }

        coordinator?.openURL(url)
    }
}

// MARK: - Private functions

private extension TokenMarketsDetailsViewModel {
    func bind() {
        quotesRepository.quotesPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .compactMap { viewModel, quotes in
                quotes[viewModel.tokenInfo.id]?.price
            }
            .assign(to: \.value, on: currentPriceSubject, ownership: .weak)
            .store(in: &bag)

        currentPriceSubject
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink { elements in
                let (viewModel, (previousValue, newValue)) = elements
                viewModel.price = viewModel.balanceFormatter.formatFiatBalance(
                    newValue,
                    formattingOptions: viewModel.fiatBalanceFormattingOptions
                )
                viewModel.priceChangeAnimation = .calculateChange(from: previousValue, to: newValue)
            }
            .store(in: &bag)

        $isLoading
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, isLoading in
                viewModel.portfolioViewModel?.isLoading = isLoading
            }
            .store(in: &bag)
    }

    func loadDetailedInfo() {
        runTask(in: self) { viewModel in
            do {
                let currencyId = viewModel.tokenInfo.id
                viewModel.log("Attempt to load token markets data for token with id: \(currencyId)")
                await viewModel.updateQuotes()
                let result = try await viewModel.dataProvider.loadTokenMarketsDetails(for: currencyId)

                await runOnMain {
                    viewModel.setupUI(using: result)
                    viewModel.isLoading = false
                }

                viewModel.scheduleQuotesUpdate()
            } catch {
                await runOnMain { viewModel.alert = error.alertBinder }
                viewModel.log("Failed to load detailed info. Reason: \(error)")
            }
        }
    }

    func scheduleQuotesUpdate() {
        log("Scheduling quote update for \(tokenInfo.id)")
        quotesUpdateScheduler = .init()
        quotesUpdateScheduler?.scheduleJob(interval: quotesUpdateTimeInterval, repeats: true, action: weakify(self, forFunction: TokenMarketsDetailsViewModel.updateQuotes))
    }

    func updateQuotes() async {
        log("Updating quotes for \(tokenInfo.id)")
        await quotesRepository.loadQuotes(currencyIds: [tokenInfo.id])
    }

    func updatePrice(_ newPrice: Decimal) {
        price = balanceFormatter.formatFiatBalance(newPrice, formattingOptions: fiatBalanceFormattingOptions)
    }

    func setupUI(using model: TokenMarketsDetailsModel) {
        loadedPriceChangeInfo = model.priceChangePercentage
        loadedInfo = model
        shortDescription = model.shortDescription
        fullDescription = model.fullDescription

        makeBlocksViewModels(using: model)
    }

    private func makePreloadBlocksViewModels() {
        portfolioViewModel = .init(
            userWalletModels: walletDataProvider.userWalletModels,
            coinId: tokenInfo.id,
            coordinator: coordinator,
            addTokenTapAction: { [weak self] in
                guard let self, let coinModel = loadedInfo?.coinModel, !coinModel.items.isEmpty else {
                    return
                }

                coordinator?.openTokenSelector(with: coinModel, with: walletDataProvider)
            }
        )
    }

    private func makeHistoryChartViewModel() {
        let historyChartProvider = CommonMarketsHistoryChartProvider(
            tokenId: tokenInfo.id,
            yAxisLabelCount: Constants.historyChartYAxisLabelCount
        )
        historyChartViewModel = MarketsHistoryChartViewModel(
            historyChartProvider: historyChartProvider,
            selectedPriceInterval: selectedPriceChangeIntervalType,
            selectedPriceIntervalPublisher: $selectedPriceChangeIntervalType
        )
    }

    func makeBlocksViewModels(using model: TokenMarketsDetailsModel) {
        if let insights = model.insights {
            insightsViewModel = .init(insights: insights, infoRouter: self)
        }

        if let metrics = model.metrics {
            metricsViewModel = .init(metrics: metrics, infoRouter: self)
        }

        pricePerformanceViewModel = .init(
            pricePerformanceData: model.pricePerformance,
            currentPricePublisher: currentPriceSubject.eraseToAnyPublisher()
        )

        linksSections = MarketsTokenDetailsLinksMapper(
            openLinkAction: weakify(self, forFunction: TokenMarketsDetailsViewModel.openLinkAction(_:))
        ).mapToSections(model.links)
    }

    func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("[TokenMarketsDetailsViewModel] - \(message())")
    }
}

extension TokenMarketsDetailsViewModel {
    func openFullDescription() {
        guard let fullDescription else {
            return
        }

        openInfoBottomSheet(title: Localization.marketsTokenDetailsAboutTokenTitle(tokenInfo.name), message: fullDescription)
    }
}

extension TokenMarketsDetailsViewModel: MarketsTokenDetailsBottomSheetRouter {
    func openInfoBottomSheet(title: String, message: String) {
        descriptionBottomSheetInfo = .init(title: title, description: message)
    }
}

// MARK: - Constants

private extension TokenMarketsDetailsViewModel {
    private enum Constants {
        static let historyChartYAxisLabelCount = 3
    }
}
