//
//  BannerPromotionService.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BannerPromotionService {
    func activePromotion(promotion: PromotionProgramName, on place: BannerPromotionPlacement) async -> ActivePromotionInfo?
    func isHidden(promotion: PromotionProgramName, on place: BannerPromotionPlacement) -> Bool
    func hide(promotion: PromotionProgramName, on place: BannerPromotionPlacement)
}

private struct BannerPromotionServiceKey: InjectionKey {
    static var currentValue: BannerPromotionService = CommonBannerPromotionService()
}

extension InjectedValues {
    var bannerPromotionService: BannerPromotionService {
        get { Self[BannerPromotionServiceKey.self] }
        set { Self[BannerPromotionServiceKey.self] = newValue }
    }
}

struct ActivePromotionInfo: Hashable {
    let bannerPromotion: PromotionProgramName
    let timeline: Timeline
    let link: URL?
}

enum BannerPromotionPlacement {
    case main
    case tokenDetails(TokenItem)

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .main:
            return .main
        case .tokenDetails:
            return .token
        }
    }
}

enum PromotionProgramName: String, Hashable, CaseIterable {
    case ring

    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .ring:
            return Analytics.ParameterValue.ring
        }
    }
}
