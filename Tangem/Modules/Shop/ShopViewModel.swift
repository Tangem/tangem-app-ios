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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

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
    @Published var canOrder = true
    @Published var orderNotification: String?
    @Published var pollingForOrder = false
    @Published var order: Order?

    @Published var error: AlertBinder?

    var applePayButtonType: PKPaymentButtonType {
        // We're using `.order` as a pre-order button. In reality you can't buy the product
        canOrder ? .buy : .order
    }

    var buyButtonText: String {
        canOrder ? Localization.shopBuyNow : Localization.shopPreOrderNow
    }

    private var shopifyProductVariants: [ProductVariant] = []
    private var currentVariantID: GraphQL.ID = .init(rawValue: "")
    private var checkoutByVariantID: [GraphQL.ID: Checkout] = [:]
    private var salesDetails: SalesDetails?
    private var initialized = false
    private let bundleChangeAnimation = Animation.easeOut(duration: 0.25)
    private unowned let coordinator: ShopViewRoutable

    init(coordinator: ShopViewRoutable) {
        self.coordinator = coordinator
        fetchSalesDetails()
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

                pollingForOrder = true
                return shopifyService.checkout(pollUntilOrder: true, checkoutID: checkoutID)
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

                loadingProducts = false

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
                    error = AppError.serverUnavailable.alertBinder
                    return
                }

                shopifyProductVariants = variants
                didSelectBundle(selectedBundle)
            }
            .store(in: &bag)
    }

    private func fetchSalesDetails() {
        runTask { [weak self] in
            guard let self else { return }

            let locale = Locale.current.languageCode ?? "en"
            let shops = "shopify"
            salesDetails = try await tangemApiService.sales(locale: locale, shops: shops)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.updateCurrentProductSalesDetails(self.selectedBundle)
            }
        }
    }

    private func updateCurrentProductSalesDetails(_ bundle: Bundle) {
        let canOrder: Bool
        let orderNotification: String?

        let productCode = bundle.salesProductCode
        if let currentProductSalesDetails = salesDetails?.sales.first(where: { $0.product.code == productCode }) {
            canOrder = (currentProductSalesDetails.state == .order)
            orderNotification = currentProductSalesDetails.notification?.description
        } else {
            canOrder = true
            orderNotification = nil
        }

        self.canOrder = canOrder
        withAnimation(bundleChangeAnimation) {
            self.orderNotification = orderNotification
        }
    }

    private func didSelectBundle(_ bundle: Bundle) {
        withAnimation(bundleChangeAnimation) {
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
        updateCurrentProductSalesDetails(bundle)
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
                checkoutByVariantID[variantID] = checkout
                if isCurrentVariantID {
                    updatePrice()
                    checkingDiscountCode = false
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

        var salesProductCode: String {
            switch self {
            case .twoCards:
                return "pack2"
            case .threeCards:
                return "pack3"
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

                coordinator.openWebCheckout(at: checkout.webUrl)

                return shopifyService.checkout(pollUntilOrder: true, checkoutID: checkoutID)
            }
            .sink { _ in

            } receiveValue: { [weak self] checkout in
                guard let self = self else { return }

                if let order = checkout.order {
                    didPlaceOrder(order)
                }

                closeWebCheckout()
            }
            .store(in: &bag)
    }

    func closeWebCheckout() {
        coordinator.closeWebCheckout()
        didCloseWebCheckout()
    }
}
