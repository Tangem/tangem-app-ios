//
//  PromotionViewModel.swift
//
//
//  Created by Andrey Chukavin on 30.05.2023.
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
        actions["\(baseUrl)/\(urlPath)/code-created"] = handleCodeCreated
        actions["\(baseUrl)/\(urlPath)/ready-for-existed-card-award"] = handleReadyForAward // TODO: REMOVE
        actions["\(baseUrl)/\(urlPath)/ready-for-existing-card-award"] = handleReadyForAward

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
            queryItems.append(URLQueryItem(name: "programName", value: promotionService.programName))
        case .default:
            break
        }

        urlComponents.queryItems = queryItems

        return urlComponents.url!
    }

    private var urlPath: String {
        "\(languageCode)/promotion-test"
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

    private unowned let coordinator: PromotionRoutable

    init(options: PromotionCoordinator.Options, coordinator: PromotionRoutable) {
        self.options = options
        self.coordinator = coordinator
    }

    func handleCodeCreated(url: String) {
        guard
            let urlComponents = URLComponents(string: url),
            let queryItem = urlComponents.queryItems?.first(where: { $0.name == "code" }),
            let code = queryItem.value
        else {
            return
        }

        promotionService.setPromoCode(code)
    }

    func handleReadyForAward(url: String) {
        promotionService.didBecomeReadyForAward()
        coordinator.closeModule()
    }

    func close() {
        coordinator.closeModule()
    }
}
