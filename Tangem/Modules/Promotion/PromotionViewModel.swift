//
//  PromotionViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class PromotionViewModel: ObservableObject {
    @Injected(\.keysManager) var keysManager: KeysManager
    @Injected(\.promotionService) var promotionService: PromotionServiceProtocol

    var headers: [String: String] {
        var headers: [String: String] = [:]
        if let tangemComAuthorization = keysManager.tangemComAuthorization {
            headers["Authorization"] = "Basic \(tangemComAuthorization)"
        }
        return headers
    }

    var urlActions: [String: (String) -> Void] {
        let baseUrl = AppEnvironment.current.tangemComBaseUrl.absoluteString

        var actions: [String: (String) -> Void] = [:]
        actions["\(baseUrl)/\(urlPath)/success"] = handlePromotionSuccess
        actions["\(baseUrl)/\(urlPath)/ready-for-existing-card-award"] = handleReadyForAward
        actions["\(baseUrl)/analytics"] = handleAnalyticsEvent

        return actions
    }

    var url: URL {
        var urlComponents = URLComponents(url: AppEnvironment.current.tangemComBaseUrl, resolvingAgainstBaseURL: false)!
        urlComponents.path = "/\(urlPath)/"

        var queryItems: [URLQueryItem] = []

        switch options {
        case .newUser:
            queryItems.append(URLQueryItem(name: "type", value: "new-card"))
            if let promoCode = promotionService.promoCode {
                queryItems.append(URLQueryItem(name: "code", value: promoCode))
            }
        case .oldUser(let cardPublicKey, let cardId, let walletId):
            queryItems.append(URLQueryItem(name: "type", value: "existing-card"))
            queryItems.append(URLQueryItem(name: "cardPublicKey", value: cardPublicKey))
            queryItems.append(URLQueryItem(name: "cardId", value: cardId))
            queryItems.append(URLQueryItem(name: "walletId", value: walletId))
            queryItems.append(URLQueryItem(name: "programName", value: promotionService.currentProgramName))
            if promotionService.questionnaireFinished {
                queryItems.append(URLQueryItem(name: "finished", value: "true"))
            }
        case .default:
            break
        }

        urlComponents.queryItems = queryItems

        return urlComponents.url!
    }

    private var urlPath: String {
        "\(languageCode)/promotion"
    }

    private var languageCode: String {
        switch Locale.current.languageCode {
        case LanguageCode.ru, LanguageCode.by:
            return LanguageCode.ru
        default:
            return LanguageCode.en
        }
    }

    private let options: PromotionCoordinator.Options

    // MARK: - Dependencies

    private weak var coordinator: PromotionRoutable?

    init(options: PromotionCoordinator.Options, coordinator: PromotionRoutable) {
        self.options = options
        self.coordinator = coordinator
    }

    func handlePromotionSuccess(url: String) {
        let newClient: Bool
        if let urlComponents = URLComponents(string: url),
           let queryItem = urlComponents.queryItems?.first(where: { $0.name == "code" }),
           let code = queryItem.value {
            newClient = true
            promotionService.setPromoCode(code)
        } else {
            newClient = false
        }

        let programName = promotionService.currentProgramName
        Analytics.logPromotionEvent(.promoSuccessOpened, programName: programName, newClient: newClient)

        promotionService.setQuestionnaireFinished(true)
    }

    func handleReadyForAward(url: String) {
        promotionService.didBecomeReadyForAward()
        coordinator?.closeModule()
    }

    func handleAnalyticsEvent(url: String) {
        guard
            let urlComponents = URLComponents(string: url),
            let event = urlComponents.queryItems?.first(where: { $0.name == "event" })?.value,
            let programName = urlComponents.queryItems?.first(where: { $0.name == "programName" })?.value
        else {
            return
        }

        switch event {
        case "promotion-buy":
            Analytics.logPromotionEvent(.promoBuy, programName: programName)
        default:
            AppLog.warning("Unknown analytics event from promotion web view \(event), program name \(programName)")
        }
    }

    func close() {
        coordinator?.closeModule()
    }
}
