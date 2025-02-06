//
//  CommonBannerPromotionService.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonBannerPromotionService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    init() {}
}

// MARK: - PromotionService

extension CommonBannerPromotionService: BannerPromotionService {
    func activePromotion(promotion: PromotionProgramName, on place: BannerPromotionPlacement) async -> ActivePromotionInfo? {
        guard !isHidden(promotion: promotion, on: place) else {
            return nil
        }

        do {
            let promotionInfo = try await tangemApiService.expressPromotion(request: .init(programName: promotion.rawValue))
            let now = Date()
            if promotionInfo.all.status == .active, now < promotionInfo.all.timeline.end {
                return .init(bannerPromotion: promotion, timeline: promotionInfo.all.timeline, link: promotionInfo.all.link)
            }
        } catch {
            AppLogger.error("Check promotions catch error", error: error)
        }

        return nil
    }

    func isHidden(promotion: PromotionProgramName, on place: BannerPromotionPlacement) -> Bool {
        switch place {
        case .main:
            return AppSettings.shared.mainPromotionDismissed.contains(promotion.rawValue)
        case .tokenDetails:
            return AppSettings.shared.tokenPromotionDismissed.contains(promotion.rawValue)
        }
    }

    func hide(promotion: PromotionProgramName, on place: BannerPromotionPlacement) {
        switch place {
        case .main:
            AppSettings.shared.mainPromotionDismissed.insert(promotion.rawValue)
        case .tokenDetails:
            AppSettings.shared.tokenPromotionDismissed.insert(promotion.rawValue)
        }
    }
}
