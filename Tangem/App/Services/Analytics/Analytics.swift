//
//  Analytics.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.03.2020.
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import BlockchainSdk
import AmplitudeSwift
import TangemSdk

class Analytics {
    @Injected(\.analyticsContext) private static var analyticsContext: AnalyticsContext
    private static var amplitude: Amplitude? = {
        guard !AppEnvironment.current.isDebug else {
            return nil
        }

        return Amplitude(configuration: Configuration(apiKey: try! CommonKeysManager().amplitudeApiKey))
    }()

    private static let firebaseLoggingQueue = DispatchQueue(
        label: "com.tangem.Analytics.firebaseLoggingQueue",
        target: .global(qos: .utility)
    )

    private init() {}

    // MARK: - Scan

    static func beginLoggingCardScan(source: CardScanSource) {
        analyticsContext.set(value: source, forKey: .scanSource, scope: .common)
        logEventInternal(source.cardScanButtonEvent)
    }

    static func endLoggingCardScan() {
        guard let source = analyticsContext.value(forKey: .scanSource, scope: .common) as? CardScanSource else {
            assertionFailure("Don't forget to call beginLoggingCardScan")
            return
        }

        analyticsContext.removeValue(forKey: .scanSource, scope: .common)
        logEventInternal(.cardWasScanned, params: [.source: source.cardWasScannedParameterValue.rawValue])
    }

    // MARK: - Others

    static func logTopUpIfNeeded(balance: Decimal, for userWalletId: UserWalletId) {
        let hasPreviousPositiveBalance = analyticsContext.value(forKey: .hasPositiveBalance, scope: .userWallet(userWalletId)) as? Bool

        // Send only first topped up event. Do not send the event to analytics on following topup events.
        if balance > 0, hasPreviousPositiveBalance == false {
            logEventInternal(.toppedUp)
            analyticsContext.set(value: true, forKey: .hasPositiveBalance, scope: .userWallet(userWalletId))
        } else if hasPreviousPositiveBalance == nil { // Do not save in a withdrawal case
            // Register the first app launch with balance.
            analyticsContext.set(value: balance > 0, forKey: .hasPositiveBalance, scope: .userWallet(userWalletId))
        }
    }

    static func logDestinationAddress(isAddressValid: Bool, source: DestinationAddressSource) {
        let validationResult: Analytics.ParameterValue = isAddressValid ? .success : .fail
        guard let parameterValue = source.parameterValue else { return }

        Analytics.log(
            .sendAddressEntered,
            params: [
                .source: parameterValue,
                .validation: validationResult,
            ]
        )
    }

    static func logPromotionEvent(_ event: Event, programName: String, newClient: Bool? = nil) {
        var params = [
            ParameterKey.programName: programName,
        ]

        if let newClient {
            let clientType: ParameterValue = newClient ? .new : .old
            params[.clientType] = clientType.rawValue
        }
        Analytics.log(event: event, params: params)
    }

    static func tryLogCardVerificationError(_ error: Error, source: Analytics.CardVerificationErrorSource) {
        guard case .cardVerificationFailed = error.toTangemSdkError() else {
            return
        }

        Analytics.log(.errorOfflineAttestationFailed, params: [.source: source.parameterValue])
    }

    // MARK: - Common

    static func log(_ event: Event, params: [ParameterKey: ParameterValue] = [:], limit: Analytics.EventLimit = .unlimited) {
        log(event: event, params: params.mapValues { $0.rawValue }, limit: limit)
    }

    static func log(
        event: Event,
        params: [ParameterKey: String],
        analyticsSystems: [Analytics.AnalyticsSystem] = [.firebase, .amplitude, .crashlytics],
        limit: Analytics.EventLimit = .unlimited
    ) {
        assert(event.canBeLoggedDirectly)

        logEventInternal(event, params: params, analyticsSystems: analyticsSystems, limit: limit)
    }

    static func debugLog(eventInfo: any AnalyticsDebugEvent) {
        logInternal(
            eventInfo.title,
            params: eventInfo.analyticsParams,
            analyticsSystems: [.crashlytics]
        )
    }

    // MARK: - Private

    fileprivate static func log(error: Error, params: [ParameterKey: String] = [:]) {
        var params = params

        switch error {
        case is WalletConnectV2Error, is WalletConnectServiceError:
            params[.errorDescription] = error.localizedDescription
            let nsError = NSError(
                domain: "WalletConnect Error",
                code: 0,
                userInfo: params.dictionaryParams
            )
            Crashlytics.crashlytics().record(error: nsError)

        case let sdkError as TangemSdkError:
            params[.errorKey] = String(describing: sdkError)
            let nsError = NSError(
                domain: "Tangem SDK Error #\(sdkError.code)",
                code: sdkError.code,
                userInfo: params.dictionaryParams
            )
            Crashlytics.crashlytics().record(error: nsError)

        case let error as DetailedError:
            let detailedDescription = error.detailedDescription
            params[.errorDescription] = detailedDescription
            let nsError = NSError(
                domain: "DetailedError",
                code: 1,
                userInfo: params.dictionaryParams
            )
            Crashlytics.crashlytics().record(error: nsError)

        default:
            Crashlytics.crashlytics().record(error: error)
        }
    }

    private static func assertCanSend(event: Event, limit: EventLimit) -> Bool {
        guard limit.isLimited else {
            return true
        }

        let extraEventId = limit.extraEventId.map { "_\($0)" } ?? ""
        let eventId = event.rawValue + extraEventId

        var eventIds = analyticsContext.value(forKey: .limitedEvents, scope: limit.contextScope) as? [String] ?? []

        if eventIds.contains(eventId) {
            return false
        }

        eventIds.append(eventId)
        analyticsContext.set(value: eventIds, forKey: .limitedEvents, scope: limit.contextScope)
        return true
    }

    private static func logEventInternal(
        _ event: Event,
        params: [ParameterKey: String] = [:],
        analyticsSystems: [Analytics.AnalyticsSystem] = [.firebase, .amplitude, .crashlytics],
        limit: Analytics.EventLimit = .unlimited
    ) {
        if AppEnvironment.current.isXcodePreview {
            return
        }

        guard assertCanSend(event: event, limit: limit) else {
            return
        }

        logInternal(
            event.rawValue,
            params: params.dictionaryParams,
            analyticsSystems: analyticsSystems
        )
    }

    private static func logInternal(
        _ event: String,
        params: [String: Any] = [:],
        analyticsSystems: [Analytics.AnalyticsSystem]
    ) {
        if AppEnvironment.current.isXcodePreview {
            return
        }

        var params = params

        if let contextualParams = analyticsContext.contextData?.analyticsParams.dictionaryParams {
            params.merge(contextualParams, uniquingKeysWith: { old, _ in old })
        }

        for system in analyticsSystems {
            switch system {
            case .firebase:
                logFirebaseInternal(event, params: params)
            case .crashlytics:
                let message = "\(event).\(params)"
                Crashlytics.crashlytics().log(message)
            case .amplitude:
                amplitude?.track(eventType: event, eventProperties: params)
            }
        }

        let printableParams: [String: String] = params.reduce(into: [:]) { $0[$1.key] = String(describing: $1.value) }
        if let data = try? JSONSerialization.data(withJSONObject: printableParams, options: .sortedKeys),
           let paramsString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: ",\"", with: ", \"") {
            let logMessage = "Analytics event: \(event). Params: \(paramsString)"
            AnalyticsLog.info(logMessage)
        }
    }

    private static func logFirebaseInternal(_ event: String, params: [String: Any]) {
        // Preform logging in an asynchronous fashion due to the need for additional event mapping and processing
        firebaseLoggingQueue.async {
            let convertedEvent = FirebaseAnalyticsEventConverter.convert(event: event)
            let convertedParams = FirebaseAnalyticsEventConverter.convert(params: params)
            FirebaseAnalytics.Analytics.logEvent(convertedEvent, parameters: convertedParams)
        }
    }
}

// MARK: - Private

private extension Dictionary where Key == Analytics.ParameterKey, Value == String {
    var dictionaryParams: [String: Any] {
        var convertedParams = [String: Any]()
        forEach { convertedParams[$0.key.rawValue] = $0.value }
        return convertedParams
    }
}

private extension Analytics.Event {
    var canBeLoggedDirectly: Bool {
        switch self {
        case .introductionProcessButtonScanCard,
             .buttonScanNewCardSettings,
             .buttonCardSignIn,
             .cardWasScanned,
             .toppedUp,
             .purchased:
            return false
        default:
            return true
        }
    }
}

// MARK: - Error extension

extension Analytics {
    static func error(error: Error) {
        self.error(error: error, params: [Analytics.ParameterKey: String]())
    }

    static func error(error: Error, params: [Analytics.ParameterKey: Analytics.ParameterValue]) {
        self.error(error: error, params: params.mapValues { $0.rawValue })
    }

    static func error(error: Error, params: [Analytics.ParameterKey: String]) {
        guard !error.toTangemSdkError().isUserCancelled else {
            return
        }

        Analytics.log(error: error, params: params)
    }
}
