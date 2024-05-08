//
//  BannerPromotionService.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol BannerPromotionService {
    func activePromotion(promotion: PromotionProgramName, on place: BannerPromotionPlace) async -> ActivePromotionInfo?
    func isHidden(promotion: PromotionProgramName, on place: BannerPromotionPlace) -> Bool
    func hide(promotion: PromotionProgramName, on place: BannerPromotionPlace)
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

enum BannerPromotionPlace: String, Hashable {
    case main
    case tokenDetails
}

enum PromotionProgramName: String, Hashable {
    // The promotion has ended
    case changelly
    // Estimated dates 13/05 - 13/06
    case travala
}
