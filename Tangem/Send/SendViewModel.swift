//
//  SendViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk
import TangemSdk
import stellarsdk

struct TextHint {
    let isError: Bool
    let message: String
}

class SendViewModel: ViewModel, ObservableObject {
    weak var navigation: NavigationCoordinator!
    weak var assembly: Assembly!
    weak var ratesService: CoinMarketCapService!
    weak var featuresService: AppFeaturesService!
    var payIDService: PayIDService? = nil
    var emailDataCollector: SendScreenDataCollector!
    
    private unowned let warningsManager: WarningsManager
    
    @Published var showCameraDeniedAlert = false
    
    // MARK: Input
    @Published var validatedClipboard: String? = nil
    @Published var destination: String = ""
    @Published var amountText: String = "0"
    
    @Published var isFiatCalculation: Bool = false
    @Published var isFeeIncluded: Bool = false
    @Published var selectedFeeLevel: Int = 1
    @Published var maxAmountTapped: Bool = false
    @Published var fees: [Amount] = []
    @Published var scannedQRCode: String = ""
    
    @ObservedObject var warnings = WarningsContainer() {
        didSet {
            warnings.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] in
                    withAnimation {
                        self?.objectWillChange.send()
                    }
                })
                .store(in: &bag)
        }
    }
    
    // MARK: UI
    var shoudShowFeeSelector: Bool {
        walletModel.walletManager.allowsFeeSelection
    }
    
    var shoudShowFeeIncludeSelector: Bool {
        amountToSend.type == .coin && !isSellingCrypto
    }
    
    var shouldShowNetworkBlock: Bool  {
        shoudShowFeeSelector || shoudShowFeeIncludeSelector
    }
    
    var isPayIdSupported: Bool {
        featuresService.canSendToPayId && payIDService != nil
    }
    
    var hasAdditionalInputFields: Bool {
        additionalInputFields != .none
    }
    
    var additionalInputFields: SendAdditionalFields {
        .fields(for: blockchain)
    }
    
    var memoPlaceholder: String {
        switch blockchain {
        case .xrp, .stellar:
            return "send_extras_hint_memo_id".localized
        case .binance:
            return "send_extras_hint_memo".localized
        default:
            return ""
        }
    }
    
    var inputDecimalsCount: Int? {
        isFiatCalculation ? 2 : amountToSend.decimals
    }
    
    @Published var isNetworkFeeBlockOpen: Bool = false
    
    // MARK: Output
    @Published var destinationHint: TextHint? = nil
    @Published var amountHint: TextHint? = nil
    @Published var sendAmount: String = " "
    @Published var sendTotal: String = " "
    @Published var sendFee: String = " "
    @Published var sendTotalSubtitle: String = " "
    @Published var isSendEnabled: Bool = false
    @Published var selectedFee: Amount? = nil
    @Published var transaction: BlockchainSdk.Transaction? = nil
    @Published var canFiatCalculation: Bool = true
    @Published var oldCardAlert: AlertBinder?
    @Published var isFeeLoading: Bool = false
    
    // MARK: Additional input
    @Published var isAdditionalInputEnabled: Bool = false
    @Published var memo: String = ""
    @Published var memoHint: TextHint? = nil
    @Published var validatedMemoId: UInt64? = nil
    @Published var validatedMemo: String? = nil
    @Published var destinationTagStr: String = ""
    @Published var destinationTagHint: TextHint? = nil
    
    @Published var sendError: AlertBinder?
    
    var cardViewModel: CardViewModel {
        didSet {
            cardViewModel
                .objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
            
            walletModel
                .objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    
    var walletModel: WalletModel {
        return cardViewModel.walletModels!.first(where: { $0.wallet.blockchain == blockchain })!
    }
    
    var bag = Set<AnyCancellable>()
    
    var currencyUnit: String {
        return isFiatCalculation ? ratesService.selectedCurrencyCode: self.amountToSend.currencySymbol
    }
    
    var walletTotalBalanceDecimals: String {
        let amount = walletModel.wallet.amounts[amountToSend.type]
        return isFiatCalculation ? walletModel.getFiat(for: amount)?.description ?? ""
            : amount?.value.description ?? ""
    }
    
    var walletTotalBalanceFormatted: String {
        let amount = walletModel.wallet.amounts[self.amountToSend.type]
        let value = getDescription(for: amount, isFiat: isFiatCalculation)
        return String(format: "send_balance_subtitle_format".localized, value)
    }
    
    //MARK: Private
    @Published private var validatedDestination: String? = nil
    @Published private var validatedAmount: Amount? = nil
    
    let amountToSend: Amount
    
    private(set) var isSellingCrypto: Bool
    
    @Published private var validatedXrpDestinationTag: UInt32? = nil
    
    private var blockchain: Blockchain
    
    init(amountToSend: Amount, blockchain: Blockchain, cardViewModel: CardViewModel, warningsManager: WarningsManager) {
        self.blockchain = blockchain
        self.cardViewModel = cardViewModel
        self.amountToSend = amountToSend
        self.warningsManager = warningsManager
        isSellingCrypto = false
        fillTotalBlockWithDefaults()
        bind()
        setupWarnings()
    }
    
    convenience init(amountToSend: Amount, destination: String, blockchain: Blockchain, cardViewModel: CardViewModel, warningsManager: WarningsManager) {
        self.init(amountToSend: amountToSend, blockchain: blockchain, cardViewModel: cardViewModel, warningsManager: warningsManager)
        isSellingCrypto = true
        self.destination = destination
        canFiatCalculation = false
        sendAmount = amountToSend.value.description
        amountText = sendAmount
        
    }
    
    private func getDescription(for amount: Amount?, isFiat: Bool) -> String {
        return isFiat ? walletModel.getFiatFormatted(for: amount) ?? ""
            : amount?.description ?? ""
    }
    
    private func fillTotalBlockWithDefaults() {
        let dummyAmount = Amount(with: amountToSend, value: 0)
        let feeDummyAmount = Amount(with: walletModel.wallet.blockchain, type: .coin, value: 0)
        
        self.sendFee = getDescription(for: feeDummyAmount, isFiat: isFiatCalculation)
        self.sendAmount = getDescription(for: dummyAmount, isFiat: isFiatCalculation)
        self.sendTotal = getDescription(for: dummyAmount, isFiat: isFiatCalculation)
        self.sendTotalSubtitle = " "
    }
    
    // MARK: - Subscriptions
    func bind() {
        bag = Set<AnyCancellable>()
        
        walletModel
            .$rates
            .map {[unowned self] newRates -> Bool in
                return newRates[self.amountToSend.currencySymbol] != nil
            }
            .weakAssign(to: \.canFiatCalculation, on: self)
            .store(in: &bag)
        
        $destination //destination validation
            .debounce(for: 1.0, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink{ [unowned self] newText in
                self.validateDestination(newText)
            }
            .store(in: &bag)
        
        $transaction    //update total block
            .combineLatest($isFiatCalculation.uiPublisherWithFirst)
            .sink { [unowned self] tx, isFiatCalculation in
                if let tx = tx {
                    self.isSendEnabled = true
                    let totalAmount = tx.amount + tx.fee
                    var totalFiatAmount: Decimal? = nil
                    
                    if let famount = self.walletModel.getFiat(for: tx.amount, roundingMode: .plain), let ffee = self.walletModel.getFiat(for: tx.fee, roundingMode: .plain) {
                        totalFiatAmount = famount + ffee
                    }
                    
                    let totalFiatAmountFormatted = totalFiatAmount?.currencyFormatted(code: self.ratesService.selectedCurrencyCode)
                    
                    if isFiatCalculation {
                        self.sendAmount = self.walletModel.getFiatFormatted(for: tx.amount,  roundingMode: .plain) ?? ""
                        self.sendTotal = totalFiatAmountFormatted ?? " "
                        self.sendTotalSubtitle = tx.amount.type == tx.fee.type ?
                            String(format: "send_total_subtitle_format".localized, totalAmount.description) :
                            String(format: "send_total_subtitle_asset_format".localized,
                                   tx.amount.description,
                                   tx.fee.description)
                    } else {
                        self.sendAmount = tx.amount.description
                        self.sendTotal =  (tx.amount + tx.fee).description
                        self.sendTotalSubtitle = totalFiatAmountFormatted == nil ? " " :  String(format: "send_total_subtitle_fiat_format".localized,
                                                                                                 totalFiatAmountFormatted!,
                                                                                                 self.walletModel.getFiatFormatted(for: tx.fee,  roundingMode: .plain)!)
                    }
                } else {
                    self.fillTotalBlockWithDefaults()
                    self.isSendEnabled = false
                }
            }
            .store(in: &bag)
        
        $isFiatCalculation //handle conversion
            .uiPublisher
            .filter {[unowned self] _ in self.amountText != "0" }
            .sink { [unowned self] value in
                guard let decimals = Decimal(string: self.amountText.replacingOccurrences(of: ",", with: ".")) else {
                   return
                }
                
                if let converted = value ? self.walletModel.getFiat(for: decimals, currencySymbol: self.amountToSend.currencySymbol)
                    : self.walletModel.getCrypto(for: Amount(with: self.amountToSend, value: decimals)) {
                    self.amountText = converted.description
                } else {
                    self.amountText = "0"
                }
                
//                self.amountText = value ? self.walletModel.getFiat(for: self.amountToSend)?.description
//                    ?? ""
//                    : self.valida.value.description
            }
            .store(in: &bag)
        
        // MARK: Amount
        $amountText
            .uiPublisher
            .combineLatest($isFiatCalculation.uiPublisherWithFirst)
            .removeDuplicates(by: { prev, current in
                prev.0 == current.0
            })
//            .filter {[unowned self] (string, isFiat) -> Bool in
//                if isFiat,
//                   let fiat = self.walletModel.getFiat(for: self.amountToSend)?.description,
//                   string == fiat {
//                    return false //prevent cross-convert after max amount tap
//                }
//                return true
//            }
            .sink{ [unowned self] newAmountString, isFiat in
                guard let decimals = Decimal(string: newAmountString.replacingOccurrences(of: ",", with: ".")) else {
                    self.amountHint = nil
                    self.validatedAmount = nil
                    return
                }
                
                let newAmountValue = isFiat ? self.walletModel.getCrypto(for: Amount(with: self.amountToSend, value: decimals)) ?? 0 : decimals
                let newAmount = Amount(with: self.amountToSend, value: newAmountValue)
                
                if let amountError = self.walletModel.walletManager.validate(amount: newAmount) {
                    self.amountHint = TextHint(isError: true, message: amountError.localizedDescription)
                    self.validatedAmount = nil
                } else {
                    self.amountHint = nil
                    self.validatedAmount = newAmount
                }
                
            }
            .store(in: &bag)
                
        $validatedAmount//update fee
            .dropFirst()
            .compactMap { $0 }
            .combineLatest($validatedDestination.compactMap { $0 })
            .flatMap { [unowned self] amount, dest -> AnyPublisher<[Amount], Never> in
                self.isFeeLoading = true
                return self.walletModel.walletManager.getFee(amount: amount, destination: dest)
                    .catch { error -> Just<[Amount]> in
                        print(error)
                        Analytics.log(error: error)
                        return Just([Amount]())
                    }.eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [unowned self] completion in
                self.isFeeLoading = false
                self.fees = []
            }, receiveValue: {[unowned self] fees in
                self.isFeeLoading = false
                self.fees = fees
            })
            .store(in: &bag)
        
        $validatedAmount
            .combineLatest($validatedDestination,
                           $selectedFee,
                           $isFeeIncluded)
            .tryMap {[unowned self] amount, destination, fee, isFeeIncluded -> BlockchainSdk.Transaction? in
                guard let amount = amount, let destination = destination, let fee = fee else {
                    return nil
                }
             
                let tx = try self.walletModel.walletManager.createTransaction(amount: isFeeIncluded ? amount - fee : amount,
                                                                              fee: fee,
                                                                              destinationAddress: destination)
                DispatchQueue.main.async {
                    self.validateWithdrawal(tx, amount)
                }
                self.amountHint = nil
                return tx
            }
            .catch {[unowned self] error -> AnyPublisher<BlockchainSdk.Transaction?, Never> in
                self.amountHint = TextHint(isError: true, message: error.localizedDescription)
                return Just(nil).eraseToAnyPublisher()
            }
            .sink{[unowned self] tx in
                self.transaction = tx
            }
            .store(in: &bag)
        
        $maxAmountTapped //handle max amount tap
            .dropFirst()
            .sink { [unowned self] _ in
                self.amountText = self.walletTotalBalanceDecimals
                withAnimation {
                    self.isFeeIncluded = true
                    self.isNetworkFeeBlockOpen = true
                }        }
            .store(in: &bag)
        
        // MARK: Fee
        $fees //handle fee selection
            .combineLatest($selectedFeeLevel)
            .sink{ [unowned self] fees, level in
                if fees.isEmpty {
                    self.selectedFee = nil
                } else {
                    self.selectedFee = fees.count > 1 ? fees[level] : fees.first!
                }
            }
            .store(in: &bag)
        
        $selectedFee //update fee label
            .uiPublisher
            .combineLatest($isFiatCalculation)
            .sink{ [unowned self] newAmount, isFiat in
                let feeDummyAmount = Amount(with: self.walletModel.wallet.blockchain, type: .coin, value: 0)
                self.sendFee = self.getDescription(for: newAmount ?? feeDummyAmount, isFiat: isFiat)
            }
            .store(in: &bag)
        
        // MARK: Memo + destination tag
        $destinationTagStr
            .uiPublisher
            .sink(receiveValue: { [unowned self] destTagStr in
                self.validatedXrpDestinationTag = nil
                self.destinationTagHint = nil
                
                if destTagStr.isEmpty { return }
                
                let tag = UInt32(destTagStr)
                self.validatedXrpDestinationTag = tag
                self.destinationTagHint = tag == nil ? TextHint(isError: true, message: "send_error_invalid_destination_tag".localized) : nil
            })
            .store(in: &bag)
        
        $memo
            .uiPublisher
            .sink(receiveValue: { [unowned self] memo in
                switch blockchain {
                case .binance:
                    self.validatedMemo = memo
                case .xrp, .stellar:
                    self.validatedMemoId = nil
                    self.memoHint = nil
                    
                    if memo.isEmpty { return }
                    
                    let memoId = UInt64(memo)
                    self.validatedMemoId = memoId
                    self.memoHint = memoId == nil  ? TextHint(isError: true, message: "send_error_invalid_memo_id".localized) : nil
                default:
                    break
                }
            })
            .store(in: &bag)
        
        $scannedQRCode
            .dropFirst()
            .sink {[unowned self] qrCodeString in
                let withoutPrefix = qrCodeString.remove(contentsOf: self.walletModel.wallet.blockchain.qrPrefixes)
                let splitted = withoutPrefix.split(separator: "?")
                self.destination = splitted.first.map { String($0) } ?? withoutPrefix
                if splitted.count > 1 {
                    let queryItems = splitted[1].lowercased().split(separator: "&")
                    for queryItem in queryItems {
                        if queryItem.contains("amount") {
                            self.amountText = queryItem.replacingOccurrences(of: "amount=", with: "")
                            break
                        }
                    }
                }
            }
            .store(in: &bag)
    }
    
    func onAppear() {
        validateClipboard()
        setupWarnings()
    }
    
    func onEnterForeground() {
        validateClipboard()
    }
    
    // MARK: - Validation
    func validateClipboard() {
        validatedClipboard = nil
        
        guard let input = UIPasteboard.general.string else {
            return
        }
        
        if payIDService?.validate(input) ?? false || validateAddress(input) {
            validatedClipboard = input
        }
    }
    
    func validateAddress(_ address: String) -> Bool {
        return walletModel.wallet.blockchain.validate(address: address)
            && !walletModel.wallet.addresses.contains(where: { $0.value == address })
    }
    
    
    func validateDestination(_ destination: String) {
        validatedDestination = nil
        destinationHint = nil
        isAdditionalInputEnabled = false
        
        if destination.isEmpty {
            return
        }
        
        if isPayIdSupported,
           let payIdService = self.payIDService,
           payIdService.validate(destination) {
            payIdService.resolve(destination) {[weak self] result in
                switch result {
                case .success(let resolvedDetails):
                    if let address = resolvedDetails.address,
                       self?.validateAddress(address) ?? false {
                        self?.validatedDestination = resolvedDetails.address
                        self?.destinationTagStr = resolvedDetails.tag ?? ""
                        self?.destinationHint = TextHint(isError: false,
                                                         message: address)
                        self?.setAdditionalInputVisibility(for: address)
                    } else {
                        self?.destinationHint = TextHint(isError: true,
                                                         message: "send_validation_invalid_address".localized)
                        self?.setAdditionalInputVisibility(for: nil)
                        
                    }
                case .failure(let error):
                    self?.destinationHint = TextHint(isError: true,
                                                     message: error.localizedDescription)
                    self?.setAdditionalInputVisibility(for: nil)
                }
                
            }
            
        } else {
            if validateAddress(destination) {
                validatedDestination = destination
                setAdditionalInputVisibility(for: destination)
            } else {
                destinationHint = TextHint(isError: true,
                                           message: "send_validation_invalid_address".localized)
                setAdditionalInputVisibility(for: nil)
            }
        }
    }
    
    func validateWithdrawal(_ transaction: BlockchainSdk.Transaction, _ totalAmount: Amount) {
        if let validator = walletModel.walletManager as? WithdrawalValidator,
           let warning = validator.validate(transaction),
           sendError == nil {
            let alert = Alert(title: Text("common_warning"),
                              message: Text(warning.warningMessage),
                              primaryButton: Alert.Button.default(Text(warning.reduceMessage),
                                                                  action: {
                
                let newAmount = totalAmount - warning.suggestedReduceAmount
                self.amountText = self.isFiatCalculation ? self.walletModel.getFiat(for: newAmount)?.description ?? "0" :
                newAmount.value.description
            }),
                              secondaryButton: Alert.Button.cancel(Text(warning.ignoreMessage),
                                                                   action: {
                
            }))
            UIApplication.shared.endEditing()
            self.sendError = AlertBinder(alert: alert, error: nil)
        }
    }
    
    // MARK: Validation end -
    
    func pasteClipboardTapped() {
        if let validatedClipboard = self.validatedClipboard {
            destination = validatedClipboard
        }
    }
    
    func setAdditionalInputVisibility(for address: String?) {
        let isInputEnabled: Bool
        defer {
            withAnimation {
                isAdditionalInputEnabled = isInputEnabled
            }
        }
        
        guard let address = address else {
            isInputEnabled = false
            return
        }
        
        switch additionalInputFields {
        case .destinationTag:
            let xrpXAddress = try? XRPAddress.decodeXAddress(xAddress: address)
            isInputEnabled = xrpXAddress == nil
        case .memo:
            isInputEnabled = true
        default:
            isInputEnabled = false
        }
    }
    
    // MARK: - Send
    func send(_ callback: @escaping () -> Void) {
        guard var tx = self.transaction else {
            return
        }
        
        if let destinationTag = self.validatedXrpDestinationTag {
            tx.params = XRPTransactionParams(destinationTag: destinationTag)
        }
        
        if let memoId = self.validatedMemoId, isAdditionalInputEnabled {
            tx.params = StellarTransactionParams(memo: .id(memoId))
        }
        
        if let memo = self.validatedMemo, isAdditionalInputEnabled {
            tx.params = BinanceTransactionParams(memo: memo)
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addLoadingView()
        
        walletModel.send(tx)
            .sink(receiveCompletion: { [unowned self] completion in
                appDelegate.removeLoadingView()
                
                if case let .failure(error) = completion {
                    if case .userCancelled = error.toTangemSdkError() {
                        return
                    }
                    
                    Analytics.logCardSdkError(error.toTangemSdkError(), for: .sendTx, card: cardViewModel.cardInfo.card, parameters: [.blockchain: walletModel.wallet.blockchain.displayName])
                    
                    emailDataCollector.lastError = error
                    self.sendError = error.alertBinder
                } else {
                    if !cardViewModel.cardInfo.card.isDemoCard {
                        if self.isSellingCrypto {
                            Analytics.log(event: .userSoldCrypto, with: [.currencyCode: self.blockchain.currencySymbol])
                        } else {
                            Analytics.logTx(blockchainName: self.blockchain.displayName)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        let alert = AlertBuilder.makeSuccessAlert(message: cardViewModel.cardInfo.card.isDemoCard ? "alert_demo_feature_disabled".localized
                                                                  : "send_transaction_success".localized) { callback() }
                        self.sendError = alert
                    }
                }
                
            }, receiveValue: { _ in  })
            .store(in: &bag)
    }
    
    func warningButtonAction(at index: Int, priority: WarningPriority, button: WarningButton) {
        guard let warning = warnings.warning(at: index, with: priority) else { return }
        
        warningsManager.hideWarning(warning)
    }
    
    func openSystemSettings() {
        UIApplication.openSystemSettings()
    }
    
    private func setupWarnings() {
        warnings = warningsManager.warnings(for: .send)
    }
}
