//
//  SendWalletSummaryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

class SendWalletSummaryViewModel: ObservableObject, Identifiable {
    let walletName: String
    let totalBalance: String

    private var bag: Set<AnyCancellable> = []

    init(walletName: String, totalBalance: String) {
        self.walletName = walletName
        self.totalBalance = totalBalance

        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
    }

    func walletNameTitle(font: UIFont) -> NSAttributedString {
        return TangemRichTextFormatter().format(Localization.sendFromWallet(walletName), font: font)
    }
}

// MARK: - Rich text formatter

private struct TangemRichTextFormatter {
    // Formatting rich text as NSAttributedString
    // Supported formats: **bold**
    func format(_ string: String, font: UIFont) -> NSAttributedString {
        var originalString = string

        let regex = try! NSRegularExpression(pattern: "\\*{2}.+?\\*{2}")

        let wholeRange = NSRange(location: 0, length: (originalString as NSString).length)
        let matches = regex.matches(in: originalString, range: wholeRange)

        let attributedString = NSMutableAttributedString(string: originalString)

        if let match = matches.first {
            let formatterTagLength = 2

            let boldTextFormatted = String(originalString[Range(match.range, in: originalString)!])
            let boldText = boldTextFormatted.dropFirst(formatterTagLength).dropLast(formatterTagLength)

            originalString = originalString.replacingOccurrences(of: boldTextFormatted, with: boldText)
            attributedString.setAttributedString(NSAttributedString(string: originalString))

            let boldFont = UIFont.systemFont(ofSize: font.pointSize, weight: .semibold)
            let boldTextRange = NSRange(location: match.range.location, length: match.range.length - 2 * formatterTagLength)
            attributedString.addAttribute(.font, value: boldFont, range: boldTextRange)
        }

        return attributedString
    }
}
