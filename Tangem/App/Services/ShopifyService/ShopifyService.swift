//
//  ShopifyService.swift
//  TangemShopify
//
//  Created by Andy on 13.12.2021.
//

import MobileBuySDK
import Combine
import PassKit

enum ShopifyError: Error {
    case unknown
    case applePayFailed
    case userError(errors: [DisplayableError])
}

class ShopifyService: ShopifyProtocol {
    @Injected(\.keysManager) var keysManager: KeysManager

    private lazy var client: Graph.Client = .init(shopDomain: shop.domain, apiKey: shop.storefrontApiKey, locale: Locale.current)

    private let testApplePayPayments: Bool
    private var shop: ShopifyShop { keysManager.shopifyShop }

    private var paySession: PaySession?
    private var paySessionPublisher: PassthroughSubject<Checkout, Error>?

    private var subscriptions: Set<AnyCancellable> = []

    private var tasks: [Task] = []

    // MARK: -

    init(testApplePayPayments: Bool = false) {
        self.testApplePayPayments = testApplePayPayments
    }

    deinit {
        cancelTasks()
        AppLog.shared.debug("ShopifyService deinitialized")
    }

    private func runTask(_ task: Task) {
        task.resume()
        tasks.append(task)
    }

    func cancelTasks() {
        AppLog.shared.debug("Shopify: Cancelling tasks")
        tasks.forEach { $0.cancel() }
    }

    // MARK: - Getting data

    func shopName() -> AnyPublisher<String, Error> {
        let query = Storefront.buildQuery { $0
            .shop { $0
                .name()
            }
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }

            let task = client.queryGraphWith(query) { query, error in
                if let query = query {
                    promise(.success(query.shop.name))
                    return
                }

                if let error = error {
                    AppLog.shared.debug("Failed to get shop info")
                    promise(.failure(error))
                    return
                }

                promise(.failure(ShopifyError.unknown))
            }

            runTask(task)
        }.eraseToAnyPublisher()
    }

    func products(collectionTitleFilter: String? = nil) -> AnyPublisher<[Collection], Error> {
        let filter: String?
        if let titleFilter = collectionTitleFilter {
            filter = "title:\"\(titleFilter)\""
        } else {
            filter = nil
        }

        let query = Storefront.buildQuery { $0
            .collections(first: 250, query: filter) { $0
                .edges { $0
                    .node { $0
                        .collectionFieldsFragment()
                    }
                }
            }
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }

            let task = client.queryGraphWith(query) { response, error in
                if let response = response {
                    let collections = response.collections.edges.map { Collection($0.node) }
                    promise(.success(collections))
                    return
                }

                if let error = error {
                    AppLog.shared.debug("Failed to get collections")
                    AppLog.shared.error(error)
                    promise(.failure(error))
                    return
                }

                AppLog.shared.debug("Failed to get collections")
                promise(.failure(ShopifyError.unknown))
            }

            runTask(task)
        }
        .eraseToAnyPublisher()
    }

    func checkout(pollUntilOrder: Bool, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let query = Storefront.buildQuery { $0
            .node(id: checkoutID) { $0
                .onCheckout { $0
                    .checkoutFieldsFragment()
                }
            }
        }

        let future: Future<Checkout, Error> = Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }

            let retryHandler: Graph.RetryHandler<Storefront.QueryRoot> = .init { response, error in
                guard pollUntilOrder else { return false }

                guard
                    let checkout = response?.node as? Storefront.Checkout,
                    let _ = checkout.order
                else {
                    AppLog.shared.debug("Not ordered yet, continuing polling")
                    return true
                }

                return false
            }

            let task = client.queryGraphWith(query, retryHandler: retryHandler) { response, error in
                if let queriedCheckout = response?.node as? Storefront.Checkout {
                    promise(.success(Checkout(queriedCheckout)))
                    return
                }

                if let error = error {
                    AppLog.shared.debug("Failed to get checkout")
                    AppLog.shared.error(error)
                    promise(.failure(error))
                    return
                }

                AppLog.shared.debug("Failed to get checkout")
                promise(.failure(ShopifyError.unknown))
            }
            runTask(task)
        }

        return future.eraseToAnyPublisher()
    }

    func createCheckout(checkoutID: GraphQL.ID?, lineItems: [CheckoutLineItem]) -> AnyPublisher<Checkout, Error> {
        let storefrontLineItems: [Storefront.CheckoutLineItemInput] = lineItems.map { .create(quantity: $0.quantity, variantId: $0.id) }
        if let checkoutID = checkoutID {
            let mutation = Storefront.buildMutation { $0
                .checkoutLineItemsReplace(lineItems: storefrontLineItems, checkoutId: checkoutID) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .userErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Replacing checkout items", waitUntilReady: false) {
                $0.checkoutLineItemsReplace
            }
        } else {
            let checkout = Storefront.CheckoutCreateInput.create(lineItems: .value(storefrontLineItems), allowPartialAddresses: .value(true))
            let mutation = Storefront.buildMutation { $0
                .checkoutCreate(input: checkout) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .checkoutUserErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Creating checkout", waitUntilReady: false) {
                $0.checkoutCreate
            }
        }
    }

    func applyDiscount(_ discountCode: String?, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        if let discountCode = discountCode {
            let mutation = Storefront.buildMutation { $0
                .checkoutDiscountCodeApplyV2(discountCode: discountCode, checkoutId: checkoutID) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .checkoutUserErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Applying discount", waitUntilReady: false) {
                $0.checkoutDiscountCodeApplyV2
            }
        } else {
            let mutation = Storefront.buildMutation { $0
                .checkoutDiscountCodeRemove(checkoutId: checkoutID) { $0
                    .checkout { $0
                        .checkoutFieldsFragment()
                    }
                    .checkoutUserErrors { $0
                        .checkoutUserErrorFields()
                    }
                }
            }
            return runCheckoutMutation(mutation: mutation, description: "Removing discount", waitUntilReady: false) {
                $0.checkoutDiscountCodeRemove
            }
        }
    }

    func updateAddress(_ address: Address, checkoutID: GraphQL.ID, waitForShippingRates: Bool) -> AnyPublisher<Checkout, Error> {
        let input = address.mutationInput
        let mutation = Storefront.buildMutation { $0
            .checkoutShippingAddressUpdateV2(shippingAddress: input, checkoutId: checkoutID) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Updating checkout address", waitUntilReady: false, checkShippingRates: waitForShippingRates) {
            $0.checkoutShippingAddressUpdateV2
        }
    }

    func updateEmail(email: String, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let mutation = Storefront.buildMutation { $0
            .checkoutEmailUpdateV2(checkoutId: checkoutID, email: email) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Updating email", waitUntilReady: false) {
            $0.checkoutEmailUpdateV2
        }
    }

    func updateShippingRate(handle: String, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let mutation = Storefront.buildMutation { $0
            .checkoutShippingLineUpdate(checkoutId: checkoutID, shippingRateHandle: handle) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Updating shipping rate", waitUntilReady: false) {
            $0.checkoutShippingLineUpdate
        }
    }

    func completeWithTokenizedPayment(_ payment: Storefront.TokenizedPaymentInputV3, checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        let mutation = Storefront.buildMutation { $0
            .checkoutCompleteWithTokenizedPaymentV3(checkoutId: checkoutID, payment: payment) { $0
                .checkout { $0
                    .checkoutFieldsFragment()
                }
                .checkoutUserErrors { $0
                    .checkoutUserErrorFields()
                }
            }
        }
        return runCheckoutMutation(mutation: mutation, description: "Completing tokenized payment", waitUntilReady: true) {
            $0.checkoutCompleteWithTokenizedPaymentV3
        }
    }

    // MARK: - Apple Pay

    func canUseApplePay() -> Bool {
        PKPaymentAuthorizationController.canMakePayments() && shop.merchantID != nil
    }

    func startApplePaySession(checkoutID: GraphQL.ID) -> AnyPublisher<Checkout, Error> {
        guard let merchantID = shop.merchantID else {
            AppLog.shared.debug("Merchant ID not available. Cannot use Apple Pay")
            return Fail<Checkout, Error>(error: ShopifyError.applePayFailed)
                .eraseToAnyPublisher()
        }

        guard paySession == nil else {
            AppLog.shared.debug("Another pay session is in progress")
            return Fail<Checkout, Error>(error: ShopifyError.applePayFailed)
                .eraseToAnyPublisher()
        }

        checkout(pollUntilOrder: false, checkoutID: checkoutID)
            .zip(shopName())
            .sink { _ in

            } receiveValue: { [unowned self] checkout, shopName in
                paySession = PaySession(
                    shopName: shopName,
                    checkout: checkout.payCheckout,
                    currency: checkout.payCurrency,
                    merchantID: merchantID
                )
                paySession?.delegate = self
                paySession?.authorize()
            }
            .store(in: &subscriptions)

        let paySessionPublisher = PassthroughSubject<Checkout, Error>()
        self.paySessionPublisher = paySessionPublisher
        return paySessionPublisher.eraseToAnyPublisher()
    }
}

// MARK: - Apple Pay delegate

extension ShopifyService: PaySessionDelegate {
    func paySession(_ paySession: PaySession, didRequestShippingRatesFor address: PayPostalAddress, checkout: PayCheckout, provide: @escaping (PayCheckout?, [PayShippingRate]) -> Void) {
        AppLog.shared.debug("Apple Pay: Providing shipping rates...")

        // Update the checkout with an incomplete address. Full address will be given to us after authorisation.
        updateAddress(Address(address), checkoutID: GraphQL.ID(rawValue: checkout.id), waitForShippingRates: true)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    AppLog.shared.debug("Apple Pay: Failed to update shipping address")
                    AppLog.shared.error(error)
                    provide(nil, [])
                case .finished:
                    break
                }
            } receiveValue: { checkout in
                let payCheckout = checkout.payCheckout
                let payShippingRates = checkout.availableShippingRates.map { $0.payShippingRate }
                provide(payCheckout, payShippingRates)
            }
            .store(in: &subscriptions)
    }

    // WARNING:
    // This method is only called for checkouts that DON'T require shipping
    func paySession(_ paySession: PaySession, didUpdateShippingAddress address: PayPostalAddress, checkout: PayCheckout, provide: @escaping (PayCheckout?) -> Void) {
        AppLog.shared.debug("Apple Pay: Did update shipping address...")
        provide(nil)
    }

    func paySession(_ paySession: PaySession, didSelectShippingRate shippingRate: PayShippingRate, checkout: PayCheckout, provide: @escaping (PayCheckout?) -> Void) {
        AppLog.shared.debug("Apple Pay: Updating shipping rates...")

        updateShippingRate(handle: shippingRate.handle, checkoutID: GraphQL.ID(rawValue: checkout.id))
            .sink { completion in
                switch completion {
                case .failure(let error):
                    AppLog.shared.debug("Apple Pay: Failed to update shipping rate")
                    AppLog.shared.error(error)
                    provide(nil)
                case .finished:
                    break
                }
            } receiveValue: { checkout in
                let payCheckout = checkout.payCheckout
                provide(payCheckout)
            }
            .store(in: &subscriptions)
    }

    func paySession(_ paySession: PaySession, didAuthorizePayment authorization: PayAuthorization, checkout: PayCheckout, completeTransaction: @escaping (PaySession.TransactionStatus) -> Void) {
        AppLog.shared.debug("Apple Pay: Authorization granted, proceeding to checkout")

        guard let email = authorization.shippingAddress.email else {
            AppLog.shared.debug("No email provided")
            completeTransaction(.failure)
            return
        }

        guard let currencyCode = Storefront.CurrencyCode(rawValue: checkout.currencyCode) else {
            AppLog.shared.debug("Apple Pay: Invalid currency: \(checkout.currencyCode)")
            completeTransaction(.failure)
            return
        }

        let address = Address(authorization.shippingAddress)

        let payment: Storefront.TokenizedPaymentInputV3 = .create(
            paymentAmount: .create(amount: checkout.paymentDue, currencyCode: currencyCode),
            idempotencyKey: paySession.identifier,
            billingAddress: address.mutationInput,
            paymentData: authorization.token,
            type: .applePay,
            test: .value(testApplePayPayments)
        )

        let checkoutID = GraphQL.ID(rawValue: checkout.id)

        updateAddress(address, checkoutID: checkoutID, waitForShippingRates: false)
            .zip(updateEmail(email: email, checkoutID: checkoutID))
            .flatMap { [unowned self] _, _ in
                completeWithTokenizedPayment(payment, checkoutID: checkoutID)
            }
            .sink { [unowned self] completion in
                AppLog.shared.debug("Apple Pay: finished with completion: \(completion)")
                switch completion {
                case .finished:
                    completeTransaction(.success)
                    paySessionPublisher?.send(completion: .finished)
                case .failure:
                    completeTransaction(.failure)
                    paySessionPublisher?.send(completion: .failure(ShopifyError.applePayFailed))
                }

                paySessionPublisher = nil
            } receiveValue: { [unowned self] checkout in
                AppLog.shared.debug("Apple Pay: Finished with checkout: \(checkout)")
                paySessionPublisher?.send(checkout)
            }
            .store(in: &subscriptions)
    }

    func paySessionDidFinish(_ paySession: PaySession) {
        self.paySession = nil
        paySessionPublisher?.send(completion: .failure(ShopifyError.applePayFailed))
    }

    // MARK: - Updating checkout

    private func retryHandler(
        waitUntilReady: Bool,
        checkShippingRates: Bool,
        payloadProvider: @escaping (Storefront.Mutation) -> CheckoutPayload?
    ) -> Graph.RetryHandler<Storefront.Mutation> {
        // Return true if request needs to be retried
        .init { response, error in
            guard let response = response else { return true }

            let payload = payloadProvider(response)
            let checkout = payload?.checkout

            if let userErrors = payload?.checkoutUserErrors, !userErrors.isEmpty {
                AppLog.shared.debug("User errors: \(userErrors)")
                return false
            }

            if checkShippingRates, checkout?.availableShippingRates?.ready != true {
                AppLog.shared.debug("Shipping rates not ready, continue polling")
                return true
            }

            if waitUntilReady,
               let checkoutReady = checkout?.ready,
               !checkoutReady {
                AppLog.shared.debug("Checkout is not ready, continue polling")
                return true
            }

            return false
        }
    }

    private func runCheckoutMutation(
        mutation: Storefront.MutationQuery,
        description: String,
        waitUntilReady: Bool,
        checkShippingRates: Bool = false,
        payloadProvider: @escaping (Storefront.Mutation) -> CheckoutPayload?
    ) -> AnyPublisher<Checkout, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(ShopifyError.unknown))
                return
            }

            let retryHandler = retryHandler(waitUntilReady: waitUntilReady, checkShippingRates: checkShippingRates, payloadProvider: payloadProvider)
            let task = client.mutateGraphWith(mutation, retryHandler: retryHandler) { mutation, error in
                guard
                    let mutation = mutation,
                    let payload = payloadProvider(mutation)
                else {
                    AppLog.shared.debug("No payload received")
                    promise(.failure(ShopifyError.unknown))
                    return
                }

                if let checkout = payload.checkout {
                    promise(.success(Checkout(checkout)))
                    return
                }

                let userErrors = payload.checkoutUserErrors
                if !userErrors.isEmpty {
                    AppLog.shared.debug("Checkout modification failed (\(description)): \(userErrors)")
                    promise(.failure(ShopifyError.userError(errors: userErrors)))
                    return
                }

                if let error = error {
                    AppLog.shared.debug("Checkout modification failed (\(description))")
                    AppLog.shared.error(error)
                    promise(.failure(error))
                    return
                }

                AppLog.shared.debug("Checkout modification failed (\(description)):")
                promise(.failure(ShopifyError.unknown))
            }

            runTask(task)
        }
        .eraseToAnyPublisher()
    }
}
