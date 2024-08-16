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

    @Published private(set) var priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .neutral
    @Published private(set) var isLoading = true
    @Published private(set) var state: ViewState = .loading
    @Published var selectedPriceChangeIntervalType: MarketsPriceIntervalType
    @Published var alert: AlertBinder?

    // MARK: Blocks

    @Published private(set) var insightsViewModel: MarketsTokenDetailsInsightsViewModel?
    @Published private(set) var metricsViewModel: MarketsTokenDetailsMetricsViewModel?
    @Published private(set) var pricePerformanceViewModel: MarketsTokenDetailsPricePerformanceViewModel?
    @Published private(set) var linksSections: [TokenMarketsDetailsLinkSection] = []
    @Published private(set) var portfolioViewModel: MarketsPortfolioContainerViewModel?
    @Published private(set) var historyChartViewModel: MarketsHistoryChartViewModel?

    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

    // Private published properties used for calculation `price`, `priceChangeState` and `priceDate` properties

    @Published private var selectedDate: Date?
    @Published private var priceFromQuoteRepository: Decimal?
    @Published private var priceFromSelectedChartValue: Decimal?

    @Published private var priceChangeInfo: [String: Decimal] = [:]
    @Published private var loadedTokenDetailsPriceChangeInfo: [String: Decimal] = [:]

    @Published private var tokenInsights: TokenMarketsDetailsInsights?

    var price: String? { priceInfo?.price }

    var priceChangeState: TokenPriceChangeView.State? { priceInfo?.priceChangeState }

    private var priceInfo: TokenMarketsDetailsPriceInfoHelper.PriceInfo? {
        guard let currentPrice = priceFromQuoteRepository else {
            return nil
        }

        if let selectedPrice = priceFromSelectedChartValue {
            return priceHelper.makePriceInfo(currentPrice: currentPrice, selectedPrice: selectedPrice)
        }

        return priceHelper.makePriceInfo(
            currentPrice: currentPrice,
            priceChangeInfo: priceChangeInfo,
            selectedPriceChangeIntervalType: selectedPriceChangeIntervalType
        )
    }

    var priceDate: String {
        guard let priceDate = dateHelper.makeDate(
            selectedDate: selectedDate,
            selectedPriceChangeIntervalType: selectedPriceChangeIntervalType
        ) else {
            // TODO: Andrey Fedorov - Temporary workaround until the issue with obtaining the beginning of `all` time interval is resolved (IOS-7476)
            return selectedPriceChangeIntervalType == .all ? Localization.commonAll : Localization.commonToday
        }

        return "\(dateFormatter.string(from: priceDate)) – \(Localization.commonNow)"
    }

    var tokenName: String { tokenInfo.name }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    var priceChangeIntervalOptions: [MarketsPriceIntervalType] { MarketsPriceIntervalType.allCases }

    var allDataLoadFailed: Bool { state == .failedToLoadAllData }

    private weak var coordinator: TokenMarketsDetailsRoutable?

    private lazy var currentPricePublisher: some Publisher<Decimal?, Never> = quotesPublisher
        .map { $0?.price }
        .share(replay: 1)

    private lazy var quotesPublisher: some Publisher<TokenQuote?, Never> = {
        let currencyId = tokenInfo.id

        return quotesRepository
            .quotesPublisher
            .receive(on: DispatchQueue.main)
            .map { $0[currencyId] }
            .share(replay: 1)
    }()

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

    private let tokenInfo: MarketsTokenModel
    private let dataProvider: MarketsTokenDetailsDataProvider
    private let marketsQuotesUpdateHelper: MarketsQuotesUpdateHelper
    private let walletDataProvider = MarketsWalletDataProvider()

    private var loadedInfo: TokenMarketsDetailsModel?
    private var loadingTask: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        tokenInfo: MarketsTokenModel,
        dataProvider: MarketsTokenDetailsDataProvider,
        marketsQuotesUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: TokenMarketsDetailsRoutable?
    ) {
        self.tokenInfo = tokenInfo
        self.dataProvider = dataProvider
        self.marketsQuotesUpdateHelper = marketsQuotesUpdateHelper
        self.coordinator = coordinator
        selectedPriceChangeIntervalType = .day

        let tokenQuoteHelper = MarketsTokenQuoteHelper()
        loadedTokenDetailsPriceChangeInfo = tokenQuoteHelper.makePriceChangeIntervalsDictionary(
            from: quotesRepository.quote(for: tokenInfo.id)
        ) ?? tokenInfo.priceChangePercentage

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

    func loadDetailedInfo() {
        isLoading = true
        loadingTask?.cancel()
        loadingTask = runTask(in: self) { viewModel in
            do {
                let baseCurrencyCode = await AppSettings.shared.selectedCurrencyCode
                let currencyId = viewModel.tokenInfo.id
                viewModel.log("Attempt to load token markets data for token with id: \(currencyId)")
                let result = try await viewModel.dataProvider.loadTokenMarketsDetails(for: currencyId, baseCurrencyCode: baseCurrencyCode)
                viewModel.marketsQuotesUpdateHelper.updateQuote(marketToken: result, for: baseCurrencyCode)
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
        loadedTokenDetailsPriceChangeInfo = model.priceChangePercentage
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
            .assign(to: \.priceFromQuoteRepository, on: self, ownership: .weak)
            .store(in: &bag)

        currentPricePublisher
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .filter { viewModel, _ in
                // Filtered out if the chart is being dragged at the moment
                viewModel.priceFromSelectedChartValue == nil
            }
            .map(\.1)
            .withPrevious()
            .map(ForegroundBlinkAnimationModifier.Change.calculateChange(from:to:))
            .assign(to: \.priceChangeAnimation, on: self, ownership: .weak)
            .store(in: &bag)

        quotesPublisher
            .combineLatest($loadedTokenDetailsPriceChangeInfo)
            .map { quotes, detailsPriceChangeInfo in
                let tokenQuoteHelper = MarketsTokenQuoteHelper()
                guard let quotesPriceChange = tokenQuoteHelper.makePriceChangeIntervalsDictionary(from: quotes) else {
                    return detailsPriceChangeInfo
                }

                let mergedData = quotesPriceChange.merging(detailsPriceChangeInfo, uniquingKeysWith: { quotes, _ in return quotes })
                return mergedData
            }
            .assign(to: \.priceChangeInfo, on: self, ownership: .weak)
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
                viewModel.loadDetailedInfo()
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
            .map(\.?.date)
            .assign(to: \.selectedDate, on: self, ownership: .weak)
            .store(in: &bag)

        selectedChartValuePublisher
            .map(\.?.price)
            .assign(to: \.priceFromSelectedChartValue, on: self, ownership: .weak)
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

        let pricePerformanceCurrentPricePublisher = currentPricePublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()

        pricePerformanceViewModel = .init(
            tokenSymbol: model.symbol,
            pricePerformanceData: model.pricePerformance,
            currentPricePublisher: pricePerformanceCurrentPricePublisher
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
