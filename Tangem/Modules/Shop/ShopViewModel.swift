//
//  ShopViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 08.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import MobileBuySDK
import PassKit
import SwiftUI

class ShopViewModel: ObservableObject {
    private enum ShopError: Error {
        case empty
    }

    @Injected(\.shopifyService) private var shopifyService: ShopifyProtocol

    var bag = Set<AnyCancellable>()

    // MARK: - Input

    @Published var selectedBundle: Bundle = .threeCards
    @Published var discountCode = ""
    @Published var canUseApplePay = true

    // MARK: - Output

    @Published var checkingDiscountCode = false
    @Published var showingThirdCard = true
    @Published var loadingProducts = false
    @Published var totalAmountWithoutDiscount: String? = nil
    @Published var totalAmount = ""
    @Published var pollingForOrder = false
    @Published var order: Order?

    @Published var error: AlertBinder?

    var applePayButtonType: PKPaymentButtonType {
//        preorderDeliveryDateFormatted == nil ? .buy : .order
        .order
    }

    var buyButtonText: String {
//        preorderDeliveryDateFormatted == nil ? Localization.shopBuyNow : Localization.shopOrderNow
        Localization.shopOrderNow
    }

    var preorderDeliveryDateFormatted: String?

    private var shopifyProductVariants: [ProductVariant] = []
    private var currentVariantID: GraphQL.ID = .init(rawValue: "")
    private var checkoutByVariantID: [GraphQL.ID: Checkout] = [:]
    private var initialized = false
    private unowned let coordinator: ShopViewRoutable

    init(coordinator: ShopViewRoutable) {
        self.coordinator = coordinator
    }

    deinit {
        shopifyService.cancelTasks()
    }

    func didAppear() {
        closeWebCheckout()

        fetchProduct()

        guard !initialized else {
            return
        }

        initialized = true

        canUseApplePay = shopifyService.canUseApplePay()

        $selectedBundle
            .sink { [weak self] newBundle in
                self?.didSelectBundle(newBundle)
            }
            .store(in: &bag)
    }

    func didEnterDiscountCode() {
        setDiscountCode(discountCode.isEmpty ? nil : discountCode)
    }

    func openApplePayCheckout() {
        guard let checkoutID = checkoutByVariantID[currentVariantID]?.id else {
            return
        }

        shopifyService
            .startApplePaySession(checkoutID: checkoutID)
            .flatMap { [weak self] _ -> AnyPublisher<Checkout, Error> in
                guard let self = self else { return .anyFail(error: ShopError.empty) }

                self.pollingForOrder = true
                return self.shopifyService.checkout(pollUntilOrder: true, checkoutID: checkoutID)
            }
            .sink { completion in
                AppLog.shared.debug("Finished Apple Pay session with completion: \(completion)")
                self.pollingForOrder = false
            } receiveValue: { [weak self] checkout in
                AppLog.shared.debug("Checkout after Apple Pay session with checkout: \(checkout)")
                if let order = checkout.order {
                    self?.didPlaceOrder(order)
                }
            }
            .store(in: &bag)
    }

    private func fetchProduct() {
        guard shopifyProductVariants.isEmpty else {
            return
        }

        loadingProducts = true

        shopifyService
            .products(collectionTitleFilter: nil)
            .sink { completion in

            } receiveValue: { [weak self] collections in
                guard let self = self else { return }

                self.loadingProducts = false

                // There can be multiple variants with the same SKU and the same ID along multiple products.
                let allVariants: [ProductVariant] = collections.reduce([]) { partialResult, collection in
                    let products = collection.products
                    let variants = products.reduce([]) {
                        return $0 + $1.variants
                    }
                    return partialResult + variants
                }

                let skusToDisplay = Bundle.allCases.map { $0.sku }
                let variants = skusToDisplay.compactMap { skuToDisplay in
                    allVariants.first {
                        $0.sku == skuToDisplay
                    }
                }

                guard variants.count == skusToDisplay.count else {
                    self.error = AppError.serverUnavailable.alertBinder
                    return
                }

                self.shopifyProductVariants = variants
                self.didSelectBundle(self.selectedBundle)
            }
            .store(in: &bag)
    }

    private func didSelectBundle(_ bundle: Bundle) {
        withAnimation(.easeOut(duration: 0.25)) {
            showingThirdCard = (bundle == .threeCards)
        }

        let sku = bundle.sku
        guard let variant = shopifyProductVariants.first(where: {
            $0.sku == sku
        }) else {
            return
        }

        currentVariantID = variant.id
        updatePrice()
        createCheckouts()
    }

    private func didCloseWebCheckout() {
        shopifyService.cancelTasks()
        if order == nil {
            /*
                 HACK:
                 After web checkout was displayed it becomes impossible
                 to validate a partial address on the Shopify side.
                 Thus Apple Pay becomes unusable. Re-create the checkout as a workaround.
             */
            checkoutByVariantID = [:]
            createCheckouts()
        }
    }

    private func didPlaceOrder(_ order: Order) {
        self.order = order
        Analytics.logShopifyOrder(order)
    }

    private func createCheckouts() {
        // Create a checkout for each product so that we can switch between them immediately.
        // The same logic is behind applying discount codes.
        shopifyProductVariants.forEach {
            createCheckout(variantID: $0.id)
        }
    }

    private func createCheckout(variantID: GraphQL.ID) {
        let checkoutID = checkoutByVariantID[variantID]?.id
        guard checkoutID == nil else {
            return
        }

        let lineItems: [CheckoutLineItem] = [.checkoutInput(variantID: variantID, quantity: 1)]
        shopifyService
            .createCheckout(checkoutID: checkoutID, lineItems: lineItems)
            .sink { _ in

            } receiveValue: { [weak self] checkout in
                self?.checkoutByVariantID[variantID] = checkout
            }
            .store(in: &bag)
    }

    private func setDiscountCode(_ discountCode: String?) {
        shopifyProductVariants.forEach {
            setDiscountCode(discountCode, variantID: $0.id)
        }
    }

    private func setDiscountCode(_ discountCode: String?, variantID: GraphQL.ID) {
        guard let checkoutID = checkoutByVariantID[variantID]?.id else {
            return
        }

        let isCurrentVariantID = (variantID == currentVariantID)
        if isCurrentVariantID, discountCode != nil {
            checkingDiscountCode = true
        }

        shopifyService.applyDiscount(discountCode, checkoutID: checkoutID)
            .sink { _ in

            } receiveValue: { [weak self] checkout in
                guard let self = self else { return }

                if checkout.discount == nil {
                    self.discountCode = ""
                }
                self.checkoutByVariantID[variantID] = checkout
                if isCurrentVariantID {
                    self.updatePrice()
                    self.checkingDiscountCode = false
                }
            }
            .store(in: &bag)
    }

    private func moneyFormatter(_ currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = currencyCode
        return formatter
    }

    private func updatePrice() {
        guard let currentVariant = shopifyProductVariants.first(where: {
            $0.id == currentVariantID
        }) else {
            return
        }

        let totalAmount: Decimal
        if let checkout = checkoutByVariantID[currentVariantID] {
            totalAmount = checkout.total
        } else {
            totalAmount = currentVariant.amount
        }

        let formatter = moneyFormatter(currentVariant.currencyCode)

        self.totalAmount = formatter.string(from: NSDecimalNumber(decimal: totalAmount)) ?? ""
        if let originalAmount = currentVariant.originalAmount {
            totalAmountWithoutDiscount = formatter.string(from: NSDecimalNumber(decimal: originalAmount))
        } else {
            totalAmountWithoutDiscount = nil
        }
    }

    private static func preorderDeliveryDateFormatted() -> String? {
        let lastKnownPreorderDeliveryDate = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2023, month: 6, day: 10).date!

        let today = Date()
        let calendar = Calendar.current
        let canPreorder = calendar.compare(today, to: lastKnownPreorderDeliveryDate, toGranularity: .day) == .orderedAscending
        guard canPreorder else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        return dateFormatter.string(from: lastKnownPreorderDeliveryDate)
    }
}

extension ShopViewModel {
    enum Bundle: String, CaseIterable, Identifiable {
        case twoCards
        case threeCards

        var id: Self { self }

        var sku: String {
            switch self {
            case .twoCards:
                return "TG115X2-S"
            case .threeCards:
                return "TG115X3-S"
            }
        }
    }
}

// MARK: - Navigation

extension ShopViewModel {
    func openWebCheckout() {
        guard let checkoutID = checkoutByVariantID[currentVariantID]?.id else {
            return
        }

        Analytics.log(.redirected)

        // Checking order ID
        shopifyService.checkout(pollUntilOrder: false, checkoutID: checkoutID)
            .flatMap { [weak self] checkout -> AnyPublisher<Checkout, Error> in
                guard let self = self else { return .anyFail(error: ShopError.empty) }

                self.coordinator.openWebCheckout(at: checkout.webUrl)

                return self.shopifyService.checkout(pollUntilOrder: true, checkoutID: checkoutID)
            }
            .sink { _ in

            } receiveValue: { [weak self] checkout in
                guard let self = self else { return }

                if let order = checkout.order {
                    self.didPlaceOrder(order)
                }

                self.closeWebCheckout()
            }
            .store(in: &bag)
    }

    func closeWebCheckout() {
        coordinator.closeWebCheckout()
        didCloseWebCheckout()
    }
}
