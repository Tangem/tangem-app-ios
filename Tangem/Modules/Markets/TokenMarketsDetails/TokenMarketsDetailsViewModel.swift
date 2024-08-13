//
//  TokenMarketsDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

class TokenMarketsDetailsViewModel: ObservableObject {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    @Published private(set) var price: String?
    @Published private(set) var priceChangeState: TokenPriceChangeView.State?
    @Published var priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .neutral
    @Published var selectedPriceChangeIntervalType: MarketsPriceIntervalType
    @Published var isLoading = true
    @Published var alert: AlertBinder?
    @Published var state: ViewState = .loading

    // MARK: Blocks

    @Published var insightsViewModel: MarketsTokenDetailsInsightsViewModel?
    @Published var metricsViewModel: MarketsTokenDetailsMetricsViewModel?
    @Published var pricePerformanceViewModel: MarketsTokenDetailsPricePerformanceViewModel?
    @Published var linksSections: [TokenMarketsDetailsLinkSection] = []
    @Published var portfolioViewModel: MarketsPortfolioContainerViewModel?
    @Published private(set) var historyChartViewModel: MarketsHistoryChartViewModel?

    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

    @Published private var selectedDate: Date?
    @Published private var loadedPriceChangeInfo: [String: Decimal] = [:]
    @Published private var tokenInsights: TokenMarketsDetailsInsights?

    var tokenName: String {
        tokenInfo.name
    }

    var priceDate: String {
        guard let selectedDate else {
            // TODO: Andrey Fedorov - Temporary workaround until the issue with obtaining the beginning of `all` time interval is resolved (IOS-7476)
            return selectedPriceChangeIntervalType == .all ? Localization.commonAll : Localization.commonToday
        }

        return "\(dateFormatter.string(from: selectedDate)) – \(Localization.commonNow)"
    }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    var priceChangeIntervalOptions: [MarketsPriceIntervalType] {
        return MarketsPriceIntervalType.allCases
    }

    var allDataLoadFailed: Bool {
        state == .failedToLoadAllData
    }

    private weak var coordinator: TokenMarketsDetailsRoutable?

    private let balanceFormatter = BalanceFormatter()

    private lazy var priceHelper = TokenMarketsDetailsPriceInfoHelper(fiatBalanceFormattingOptions: fiatBalanceFormattingOptions)
    private lazy var dateHelper = TokenMarketsDetailsDateHelper(initialDate: initialDate)

    // The date when this VM was initialized (i.e. the screen was opened)
    private let initialDate = Date()

    // TODO: Andrey Fedorov - Add different date & time formats for different selected time intervals (IOS-7476)
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:mm"
        return dateFormatter
    }()

    private let fiatBalanceFormattingOptions: BalanceFormattingOptions = .init(
        minFractionDigits: 2,
        maxFractionDigits: 8,
        formatEpsilonAsLowestRepresentableValue: false,
        roundingType: .defaultFiat(roundingMode: .bankers)
    )
    private let defaultAmountNotationFormatter = DefaultAmountNotationFormatter()

    private var isReceivingSelectedChartValues = false

    private lazy var currentPricePublisher: some Publisher<Decimal, Never> = {
        let currencyId = tokenInfo.id

        return quotesRepository.quotesPublisher
            .receive(on: DispatchQueue.main)
            .map { $0[currencyId]?.price }
            .prepend(tokenInfo.currentPrice)
            .compactMap { $0 }
            .share(replay: 1)
    }()

    private let tokenInfo: MarketsTokenModel
    private let dataProvider: MarketsTokenDetailsDataProvider
    private let walletDataProvider = MarketsWalletDataProvider()

    private var loadedInfo: TokenMarketsDetailsModel?
    private var loadingTask: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        tokenInfo: MarketsTokenModel,
        dataProvider: MarketsTokenDetailsDataProvider,
        coordinator: TokenMarketsDetailsRoutable?
    ) {
        self.tokenInfo = tokenInfo
        self.dataProvider = dataProvider
        self.coordinator = coordinator
        selectedPriceChangeIntervalType = .day
        loadedPriceChangeInfo = tokenInfo.priceChangePercentage

        bind()
        loadDetailedInfo()
        makePreloadBlocksViewModels()
        makeHistoryChartViewModel()
        bindToHistoryChartViewModel()
    }

    deinit {
        loadingTask?.cancel()
        loadingTask = nil
    }

    // MARK: - Actions

    func onAppear() {
        Analytics.log(event: .marketsTokenChartScreenOpened, params: [.token: tokenInfo.symbol])
    }

    func reloadAllData() {
        loadDetailedInfo()
        historyChartViewModel?.reload()
    }

    func loadDetailedInfo() {
        isLoading = true
        loadingTask?.cancel()
        loadingTask = runTask(in: self) { viewModel in
            do {
                let currencyId = viewModel.tokenInfo.id
                viewModel.log("Attempt to load token markets data for token with id: \(currencyId)")
                let result = try await viewModel.dataProvider.loadTokenMarketsDetails(for: currencyId)
                await viewModel.handleLoadDetailedInfo(.success(result))
            } catch {
                await viewModel.handleLoadDetailedInfo(.failure(error))
            }
            viewModel.loadingTask = nil
        }.eraseToAnyCancellable()
    }

    func openLinkAction(_ info: MarketsTokenDetailsLinks.LinkInfo) {
        Analytics.log(event: .marketsButtonLinks, params: [.link: info.title])

        guard let url = URL(string: info.link) else {
            log("Failed to create link from: \(info.link)")
            return
        }

        coordinator?.openURL(url)
    }

    func openFullDescription() {
        guard let fullDescription = loadedInfo?.fullDescription else {
            return
        }

        openInfoBottomSheet(title: Localization.marketsTokenDetailsAboutTokenTitle(tokenInfo.name), message: fullDescription)
    }
}

// MARK: - Details response processing

private extension TokenMarketsDetailsViewModel {
    func handleLoadDetailedInfo(_ result: Result<TokenMarketsDetailsModel, Error>) async {
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        do {
            let detailsModel = try result.get()
            await setupUI(using: detailsModel)
        } catch {
            if error.isCancellationError {
                return
            }

            await setupFailedState()
            log("Failed to load detailed info. Reason: \(error)")
        }
    }

    @MainActor
    func setupUI(using model: TokenMarketsDetailsModel) {
        loadedPriceChangeInfo = model.priceChangePercentage
        loadedInfo = model
        state = .loaded(model: model)

        makeBlocksViewModels(using: model)
    }

    @MainActor
    func setupFailedState() {
        if case .failed = historyChartViewModel?.viewState {
            state = .failedToLoadAllData
        } else if state != .failedToLoadAllData {
            state = .failedToLoadDetails
        }
    }
}

// MARK: - Private functions

private extension TokenMarketsDetailsViewModel {
    func bind() {
        currentPricePublisher
            .withPrevious()
            .withWeakCaptureOf(self)
            .filter { !$0.0.isReceivingSelectedChartValues } // Filtered out if the chart is being dragged
            .sink { input in
                let (viewModel, (oldValue, newValue)) = input
                let priceInfo = viewModel.priceHelper.makePriceInfo(
                    currentPrice: newValue,
                    priceChangeInfo: viewModel.loadedPriceChangeInfo,
                    selectedPriceChangeIntervalType: viewModel.selectedPriceChangeIntervalType
                )
                // No need to update `priceChangeState` property here since it's updated by subscribing to
                // `selectedPriceChangeIntervalType`, `loadedPriceChangeInfo` or `selectedChartValuePublisher` properties
                viewModel.price = priceInfo.price
                viewModel.priceChangeAnimation = .calculateChange(from: oldValue, to: newValue)
            }
            .store(in: &bag)

        $loadedPriceChangeInfo
            .withLatestFrom(currentPricePublisher) { ($0, $1) }
            .withWeakCaptureOf(self)
            .filter { !$0.0.isReceivingSelectedChartValues } // Filtered out if the chart is being dragged
            .sink { input in
                let (viewModel, (loadedPriceChangeInfo, currentPrice)) = input
                let priceInfo = viewModel.priceHelper.makePriceInfo(
                    currentPrice: currentPrice,
                    priceChangeInfo: loadedPriceChangeInfo,
                    selectedPriceChangeIntervalType: viewModel.selectedPriceChangeIntervalType
                )
                viewModel.price = priceInfo.price
                viewModel.priceChangeState = priceInfo.priceChangeState
            }
            .store(in: &bag)

        $selectedPriceChangeIntervalType
            .removeDuplicates()
            .withLatestFrom(currentPricePublisher) { ($0, $1) }
            .withWeakCaptureOf(self)
            .sink { input in
                let (viewModel, (selectedIntervalType, currentPrice)) = input
                let priceInfo = viewModel.priceHelper.makePriceInfo(
                    currentPrice: currentPrice,
                    priceChangeInfo: viewModel.loadedPriceChangeInfo,
                    selectedPriceChangeIntervalType: selectedIntervalType
                )
                // No need to update `price` property here since it's updated by subscribing to `currentPricePublisher`
                viewModel.priceChangeState = priceInfo.priceChangeState
                viewModel.updateSelectedDate(
                    externallySelectedDate: nil,
                    selectedPriceChangeIntervalType: selectedIntervalType
                )
            }
            .store(in: &bag)

        $isLoading
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, isLoading in
                viewModel.portfolioViewModel?.isLoading = isLoading
            }
            .store(in: &bag)

        AppSettings.shared.$selectedCurrencyCode
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.reloadAllData()
            }
            .store(in: &bag)
    }

    func bindToHistoryChartViewModel() {
        guard let historyChartViewModel else {
            return
        }

        historyChartViewModel
            .$viewState
            .receive(on: DispatchQueue.main)
            .withPrevious()
            .withWeakCaptureOf(self)
            .sink(receiveValue: { elements in
                let (viewModel, (previousChartState, newChartState)) = elements

                switch (previousChartState, newChartState) {
                case (.failed, .failed):
                    // We need to process these cases before other so that view state remains unchanged.
                    return
                case (.failed, .loading):
                    if case .failedToLoadAllData = viewModel.state {
                        viewModel.isLoading = true
                    }
                case (_, .failed):
                    if case .failedToLoadDetails = viewModel.state {
                        viewModel.state = .failedToLoadAllData
                    }
                case (.loading, .loaded), (.failed, .loaded):
                    if case .failedToLoadAllData = viewModel.state {
                        viewModel.state = .failedToLoadDetails
                    }

                    if viewModel.loadingTask == nil {
                        viewModel.isLoading = false
                    }
                default:
                    break
                }
            })
            .store(in: &bag)

        let selectedChartValuePublisher = historyChartViewModel
            .selectedChartValuePublisher
            .removeDuplicates()
            .share(replay: 1)

        selectedChartValuePublisher
            .map { $0 != nil }
            .assign(to: \.isReceivingSelectedChartValues, on: self, ownership: .weak)
            .store(in: &bag)

        selectedChartValuePublisher
            .withLatestFrom(currentPricePublisher) { ($0, $1) }
            .withWeakCaptureOf(self)
            .sink { input in
                let (viewModel, (selectedChartValue, currentPrice)) = input
                let priceInfo: TokenMarketsDetailsPriceInfoHelper.PriceInfo
                if let selectedPrice = selectedChartValue?.price {
                    priceInfo = viewModel.priceHelper.makePriceInfo(
                        currentPrice: currentPrice,
                        selectedPrice: selectedPrice
                    )
                } else {
                    // If there is no `selectedChartValue` - we're setting both `price` and `priceChangeState`
                    // to the latest value received from the `currentPricePublisher` publisher
                    priceInfo = viewModel.priceHelper.makePriceInfo(
                        currentPrice: currentPrice,
                        priceChangeInfo: viewModel.loadedPriceChangeInfo,
                        selectedPriceChangeIntervalType: viewModel.selectedPriceChangeIntervalType
                    )
                }
                viewModel.price = priceInfo.price
                viewModel.priceChangeState = priceInfo.priceChangeState
            }
            .store(in: &bag)

        selectedChartValuePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, selectedChartValue in
                viewModel.updateSelectedDate(
                    externallySelectedDate: selectedChartValue?.date,
                    selectedPriceChangeIntervalType: viewModel.selectedPriceChangeIntervalType
                )
            }
            .store(in: &bag)
    }

    func makePreloadBlocksViewModels() {
        portfolioViewModel = .init(
            userWalletModels: walletDataProvider.userWalletModels,
            coinId: tokenInfo.id,
            coordinator: coordinator,
            addTokenTapAction: { [weak self] in
                guard let self, let coinModel = loadedInfo?.coinModel, !coinModel.items.isEmpty else {
                    return
                }

                Analytics.log(event: .marketsButtonAddToPortfolio, params: [.token: coinModel.symbol])

                coordinator?.openTokenSelector(with: coinModel, with: walletDataProvider)
            }
        )
    }

    func makeHistoryChartViewModel() {
        let historyChartProvider = CommonMarketsHistoryChartProvider(
            tokenId: tokenInfo.id,
            yAxisLabelCount: Constants.historyChartYAxisLabelCount
        )
        historyChartViewModel = MarketsHistoryChartViewModel(
            tokenSymbol: tokenInfo.symbol,
            historyChartProvider: historyChartProvider,
            selectedPriceInterval: selectedPriceChangeIntervalType,
            selectedPriceIntervalPublisher: $selectedPriceChangeIntervalType
        )
    }

    func makeBlocksViewModels(using model: TokenMarketsDetailsModel) {
        setupInsights(model.insights)

        if let metrics = model.metrics {
            metricsViewModel = .init(
                metrics: metrics,
                notationFormatter: defaultAmountNotationFormatter,
                cryptoCurrencyCode: model.symbol,
                infoRouter: self
            )
        }

        pricePerformanceViewModel = .init(
            tokenSymbol: model.symbol,
            pricePerformanceData: model.pricePerformance,
            currentPricePublisher: currentPricePublisher.eraseToAnyPublisher()
        )

        linksSections = MarketsTokenDetailsLinksMapper(
            openLinkAction: weakify(self, forFunction: TokenMarketsDetailsViewModel.openLinkAction(_:))
        ).mapToSections(model.links)
    }

    func setupInsights(_ insights: TokenMarketsDetailsInsights?) {
        defer {
            tokenInsights = insights
        }

        guard let insights else {
            insightsViewModel = nil
            return
        }

        if insightsViewModel == nil {
            insightsViewModel = .init(
                tokenSymbol: tokenInfo.symbol,
                insights: insights,
                insightsPublisher: $tokenInsights,
                notationFormatter: defaultAmountNotationFormatter,
                infoRouter: self
            )
        }
    }

    func updateSelectedDate(externallySelectedDate: Date?, selectedPriceChangeIntervalType: MarketsPriceIntervalType) {
        selectedDate = dateHelper.makeDate(
            selectedDate: externallySelectedDate,
            selectedPriceChangeIntervalType: selectedPriceChangeIntervalType
        )
    }
}

// MARK: - Logging

private extension TokenMarketsDetailsViewModel {
    func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("[TokenMarketsDetailsViewModel] - \(message())")
    }
}

// MARK: - Navigation

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

extension TokenMarketsDetailsViewModel {
    enum ViewState: Equatable {
        case loading
        case failedToLoadDetails
        case failedToLoadAllData
        case loaded(model: TokenMarketsDetailsModel)
    }
}
