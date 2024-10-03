//
//  OrganizeTokensListCornerRadiusParametersProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 08.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct UIKit.UIRectCorner

struct OrganizeTokensListCornerRadiusParametersProvider {
    private let sections: [OrganizeTokensListSection]
    private let cornerRadius: CGFloat

    init(
        sections: [OrganizeTokensListSection],
        cornerRadius: CGFloat
    ) {
        self.sections = sections
        self.cornerRadius = cornerRadius
    }

    func cornerRadius(forSectionAtIndex sectionIndex: Int) -> CGFloat {
        switch sections[sectionIndex].model.style {
        case .invisible:
            return 0.0
        case .draggable, .fixed:
            return cornerRadius
        }
    }

    func rectCorners(forSectionAtIndex sectionIndex: Int) -> UIRectCorner {
        switch sections[sectionIndex].model.style {
        case .invisible:
            return []
        case .draggable, .fixed:
            return [.topLeft, .topRight]
        }
    }

    func cornerRadius(
        forItemAt indexPath: IndexPath
    ) -> CGFloat {
        switch sections[indexPath.section].model.style {
        case .invisible:
            return (isFirstItemInSection(at: indexPath) || isLastItemInSection(at: indexPath)) ? cornerRadius : 0.0
        case .draggable, .fixed:
            return isLastItemInSection(at: indexPath) ? cornerRadius : 0.0
        }
    }

    func rectCorners(
        forItemAt indexPath: IndexPath
    ) -> UIRectCorner {
        var rectCorners = UIRectCorner()

        switch sections[indexPath.section].model.style {
        case .invisible:
            if isFirstItemInSection(at: indexPath) {
                rectCorners.insert(.topLeft)
                rectCorners.insert(.topRight)
            }
            if isLastItemInSection(at: indexPath) {
                rectCorners.insert(.bottomLeft)
                rectCorners.insert(.bottomRight)
            }
        case .draggable, .fixed:
            if isLastItemInSection(at: indexPath) {
                rectCorners.insert(.bottomLeft)
                rectCorners.insert(.bottomRight)
            }
        }

        return rectCorners
    }

    private func isFirstItemInSection(at indexPath: IndexPath) -> Bool {
        return indexPath.item == 0
    }

    private func isLastItemInSection(at indexPath: IndexPath) -> Bool {
        return indexPath.item == sections[indexPath.section].items.count - 1
    }
}
