//
//  MarketsTokenDetailsViewModel.swift
//  Tangem
//
//  Created by Andrew Son on 24/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

class MarketsTokenDetailsViewModel: MarketsBaseViewModel {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    @Published private(set) var priceChangeAnimation: ForegroundBlinkAnimationModifier.Change = .neutral
    @Published private(set) var isLoading = true
    @Published private(set) var state: ViewState = .loading
    @Published var selectedPriceChangeIntervalType: MarketsPriceIntervalType
    @Published var alert: AlertBinder?

    /// For unknown reasons, the `@self` and `@identity` of our view change when push navigation is performed in other
    /// navigation controllers in the application (on the main screen for example), which causes the state of
    /// this property to be lost if it were stored in the view as a `@State` variable.
    /// Therefore, we store it here in the view model as the `@Published` property instead of storing it in a view.
    ///
    /// Our view is initially presented when the sheet is expanded, hence the `1.0` initial value.
    @Published private(set) var overlayContentHidingInitialProgress = 1.0

    // MARK: Blocks

    @Published private(set) var insightsViewModel: MarketsTokenDetailsInsightsViewModel?
    @Published private(set) var metricsViewModel: MarketsTokenDetailsMetricsViewModel?
    @Published private(set) var pricePerformanceViewModel: MarketsTokenDetailsPricePerformanceViewModel?
    @Published private(set) var linksSections: [MarketsTokenDetailsLinkSection] = []
    @Published private(set) var portfolioViewModel: MarketsPortfolioContainerViewModel?
    @Published private(set) var historyChartViewModel: MarketsHistoryChartViewModel?
    @Published private(set) var securityScoreViewModel: MarketsTokenDetailsSecurityScoreViewModel?
    @Published private(set) var numberOfExchangesListedOn: Int?

    @Published var descriptionBottomSheetInfo: DescriptionBottomSheetInfo?

    // Private published properties used for calculation `price`, `priceChangeState` and `priceDate` properties

    @Published private var selectedDate: Date?
    @Published private var priceFromQuoteRepository: Decimal?
    @Published private var priceFromSelectedChartValue: Decimal?

    @Published private var priceChangeInfo: [String: Decimal] = [:]
    @Published private var loadedTokenDetailsPriceChangeInfo: [String: Decimal] = [:]

    @Published private var tokenInsights: MarketsTokenDetailsInsights?

    var price: String? { priceInfo?.price }

    var priceChangeState: TokenPriceChangeView.State? { priceInfo?.priceChangeState }

    var isMarketsSheetStyle: Bool { presentationStyle == .marketsSheet }

    private var priceInfo: MarketsTokenDetailsPriceInfoHelper.PriceInfo? {
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
        return dateHelper.makePriceDate(
            selectedDate: selectedDate,
            selectedPriceChangeIntervalType: selectedPriceChangeIntervalType
        )
    }

    var tokenName: String { tokenInfo.name }

    var iconURL: URL {
        let iconBuilder = IconURLBuilder()
        return iconBuilder.tokenIconURL(id: tokenInfo.id, size: .large)
    }

    var priceChangeIntervalOptions: [MarketsPriceIntervalType] { MarketsPriceIntervalType.allCases }

    var allDataLoadFailed: Bool { state == .failedToLoadAllData }

    private weak var coordinator: MarketsTokenDetailsRoutable?

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

    private lazy var priceHelper = MarketsTokenDetailsPriceInfoHelper()
    private lazy var dateHelper = MarketsTokenDetailsDateHelper(initialDate: initialDate)

    private let defaultAmountNotationFormatter = DefaultAmountNotationFormatter()

    // The date when this VM was initialized (i.e. the screen was opened)
    private let initialDate = Date()

    private let tokenInfo: MarketsTokenModel
    private let presentationStyle: MarketsTokenDetailsPresentationStyle
    private let dataProvider: MarketsTokenDetailsDataProvider
    private let marketsQuotesUpdateHelper: MarketsQuotesUpdateHelper
    private let walletDataProvider = MarketsWalletDataProvider()

    private var loadedInfo: MarketsTokenDetailsModel?
    private var loadingTask: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        tokenInfo: MarketsTokenModel,
        presentationStyle: MarketsTokenDetailsPresentationStyle,
        dataProvider: MarketsTokenDetailsDataProvider,
        marketsQuotesUpdateHelper: MarketsQuotesUpdateHelper,
        coordinator: MarketsTokenDetailsRoutable?
    ) {
        self.tokenInfo = tokenInfo
        self.presentationStyle = presentationStyle
        self.dataProvider = dataProvider
        self.marketsQuotesUpdateHelper = marketsQuotesUpdateHelper
        self.coordinator = coordinator
        selectedPriceChangeIntervalType = .day

        /// Our view is initially presented when the sheet is expanded, hence the `1.0` initial value.
        super.init(overlayContentProgressInitialValue: 1.0)

        let tokenQuoteHelper = MarketsTokenQuoteHelper()
        loadedTokenDetailsPriceChangeInfo = tokenQuoteHelper.makePriceChangeIntervalsDictionary(
            from: quotesRepository.quote(for: tokenInfo.id)
        ) ?? tokenInfo.priceChangePercentage

        bind()
        loadDetailedInfo()
        makeHistoryChartViewModel()
        makePortfolioViewModel()
        bindToHistoryChartViewModel()
    }

    deinit {
        loadingTask?.cancel()
        loadingTask = nil
    }

    // MARK: - Actions

    func loadDetailedInfo() {
        isLoading = true
        loadingTask?.cancel()
        loadingTask = runTask(in: self) { viewModel in
            do {
                let baseCurrencyCode = await AppSettings.shared.selectedCurrencyCode
                let currencyId = viewModel.tokenInfo.id
                viewModel.log("Attempt to load token markets data for token with id: \(currencyId)")
                let result = try await viewModel.dataProvider.loadTokenDetails(for: currencyId, baseCurrencyCode: baseCurrencyCode)
                viewModel.marketsQuotesUpdateHelper.updateQuote(marketToken: result, for: baseCurrencyCode)
                await viewModel.handleLoadDetailedInfo(.success(result))
            } catch {
                await viewModel.handleLoadDetailedInfo(.failure(error))
            }
            viewModel.loadingTask = nil
        }.eraseToAnyCancellable()
    }

    func openLinkAction(_ info: MarketsTokenDetailsLinks.LinkInfo) {
        Analytics.log(
            event: .marketsChartButtonLinks,
            params: [
                .token: tokenInfo.symbol.uppercased(),
                .link: info.title,
            ]
        )

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

        Analytics.log(event: .marketsChartButtonReadMore, params: [.token: tokenInfo.symbol.uppercased()])

        descriptionBottomSheetInfo = .init(
            title: Localization.marketsTokenDetailsAboutTokenTitle(tokenInfo.name),
            description: fullDescription,
            showCloseButton: true
        )
    }

    func onBackButtonTap() {
        coordinator?.closeModule()
    }

    func onOverlayContentStateChange(_ state: OverlayContentState) {
        // Our view can be recreated when the bottom sheet is in a collapsed state
        // In this case, content should be hidden (i.e. the initial progress should be zero)
        overlayContentHidingInitialProgress = state.isCollapsed ? 0.0 : 1.0
    }

    func openExchangesList() {
        guard let numberOfExchangesListedOn = numberOfExchangesListedOn else {
            return
        }

        coordinator?.openExchangesList(tokenId: tokenInfo.id, numberOfExchangesListedOn: numberOfExchangesListedOn, presentationStyle: presentationStyle)
    }

    func onGenerateAITapAction() {
        descriptionBottomSheetInfo = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }

            let dataCollector = TokenErrorDescriptionDataCollector(tokenId: tokenInfo.id, tokenName: tokenInfo.name)
            coordinator?.openMail(with: dataCollector, emailType: .appFeedback(subject: Localization.feedbackTokenDescriptionError))
        }
    }
}

// MARK: - Details response processing

private extension MarketsTokenDetailsViewModel {
    func handleLoadDetailedInfo(_ result: Result<MarketsTokenDetailsModel, Error>) async {
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

            sendBlocksAnalyticsErrors()

            log("Failed to load detailed info. Reason: \(error)")
        }
    }

    @MainActor
    func setupUI(using model: MarketsTokenDetailsModel) {
        loadedTokenDetailsPriceChangeInfo = model.priceChangePercentage
        loadedInfo = model

        state = .loaded(model: model)
        numberOfExchangesListedOn = model.numberOfExchangesListedOn

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

private extension MarketsTokenDetailsViewModel {
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

    func makeBlocksViewModels(using model: MarketsTokenDetailsModel) {
        portfolioViewModel?.update(networks: model.availableNetworks)

        setupInsights(model.insights)

        if let metrics = model.metrics {
            metricsViewModel = .init(
                metrics: metrics,
                notationFormatter: defaultAmountNotationFormatter,
                cryptoCurrencyCode: model.symbol,
                infoRouter: self
            )
        }

        if let pricePerformance = model.pricePerformance {
            let pricePerformanceCurrentPricePublisher = currentPricePublisher
                .compactMap { $0 }
                .eraseToAnyPublisher()

            pricePerformanceViewModel = .init(
                tokenSymbol: model.symbol,
                pricePerformanceData: pricePerformance,
                currentPricePublisher: pricePerformanceCurrentPricePublisher
            )
        }

        if let securityData = model.securityData {
            securityScoreViewModel = .init(
                providerData: securityData.providerData,
                securityScoreValue: securityData.totalSecurityScore,
                routable: self
            )
        }

        linksSections = MarketsTokenDetailsLinksMapper(
            openLinkAction: weakify(self, forFunction: MarketsTokenDetailsViewModel.openLinkAction(_:))
        ).mapToSections(model.links)
    }

    func makePortfolioViewModel() {
        guard isMarketsSheetStyle else {
            return
        }

        portfolioViewModel = .init(
            inputData: .init(coinId: tokenInfo.id),
            walletDataProvider: walletDataProvider,
            coordinator: coordinator,
            addTokenTapAction: { [weak self] in
                guard let self, let info = loadedInfo else {
                    return
                }

                Analytics.log(event: .marketsChartButtonAddToPortfolio, params: [.token: info.symbol.uppercased()])

                coordinator?.openTokenSelector(with: info, walletDataProvider: walletDataProvider)
            }
        )
    }

    func sendBlocksAnalyticsErrors() {
        Analytics.log(event: .marketsChartDataError, params: [
            .token: tokenInfo.symbol.uppercased(),
            .source: Analytics.ParameterValue.blocks.rawValue,
        ])
    }

    func setupInsights(_ insights: MarketsTokenDetailsInsights?) {
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

private extension MarketsTokenDetailsViewModel {
    func log(_ message: @autoclosure () -> String) {
        AppLog.shared.debug("[MarketsTokenDetailsViewModel] - \(message())")
    }
}

// MARK: - Navigation

extension MarketsTokenDetailsViewModel: MarketsTokenDetailsBottomSheetRouter {
    func openInfoBottomSheet(title: String, message: String) {
        descriptionBottomSheetInfo = .init(
            title: title,
            description: message
        )
    }
}

extension MarketsTokenDetailsViewModel: MarketsTokenDetailsSecurityScoreRoutable {}

// MARK: - Constants

private extension MarketsTokenDetailsViewModel {
    private enum Constants {
        static let historyChartYAxisLabelCount = 3
    }
}

extension MarketsTokenDetailsViewModel {
    enum ViewState: Equatable {
        case loading
        case failedToLoadDetails
        case failedToLoadAllData
        case loaded(model: MarketsTokenDetailsModel)
    }
}

enum MarketsTokenDetailsPresentationStyle {
    case marketsSheet
    case defaultNavigationStack
}
