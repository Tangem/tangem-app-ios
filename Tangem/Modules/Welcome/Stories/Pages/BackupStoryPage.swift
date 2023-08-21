//
//  BackupStoryPage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackupStoryPage: View {
    @Binding var progress: Double
    @Binding var isScanning: Bool
    let scanCard: () -> Void
    let orderCard: () -> Void

    private let descriptionFontSize: CGFloat = 24

    var body: some View {
        VStack {
            StoriesTangemLogo()
                .padding()

            VStack(spacing: 14) {
                Text(Localization.storyBackupTitle)
                    .font(.system(size: 36, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .title, textBlockAppearance: .almostImmediate)

                Text(TangemRichTextFormatter().format(Localization.storyBackupDescription, fontSize: descriptionFontSize))
                    .font(.system(size: descriptionFontSize))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .storyTextAppearanceModifier(progress: progress, type: .description, textBlockAppearance: .almostImmediate)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            GeometryReader { geometry in
                Color.clear
                    .background(
                        // Bottom card
                        Assets.Stories.tangemCard.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.7 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(-40 + 10 * progress),
                                axis: (0.2 + progress / 3, 0.1 + progress / 3, 0.4 + progress / 3),
                                perspective: 0
                            )
                            .offset(x: 0.25 * geometry.size.width, y: 0.3 * geometry.size.width)
                            .offset(x: -30 * progress, y: -30 * progress)
                            .scaleEffect(1 + 0.2 * progress)
                    )
                    .background(
                        // Top left
                        Assets.Stories.tangemCard.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.65 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(50 - progress * 15),
                                axis: (0.15 + progress / 4, 0.3 + progress / 4, 0.4 + progress / 4),
                                perspective: 0
                            )
                            .offset(x: -0.45 * geometry.size.width, y: -0.2 * geometry.size.width)
                            .offset(x: 20 * progress, y: 10 * progress)
                    )
                    .background(
                        // Top right
                        Assets.Stories.tangemCard.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 0.5 * geometry.size.width)
                            .rotation3DEffect(
                                .degrees(50 + 20 * progress),
                                axis: (0.3 + progress / 9, 0.0 + progress / 9, -0.5 + progress / 9),
                                perspective: 0
                            )
                            .offset(x: 0.3 * geometry.size.width, y: -0.3 * geometry.size.width)
                            .offset(x: -10 * progress, y: -5 * progress)
                            .scaleEffect(1 - 0.2 * progress)
                    )
            }

            Spacer()

            StoriesBottomButtons(scanColorStyle: .secondary, orderColorStyle: .primary, isScanning: $isScanning, scanCard: scanCard, orderCard: orderCard)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .background(Color("tangem_story_background").edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BackupStoryPage_Previews: PreviewProvider {
    static var previews: some View {
        BackupStoryPage(progress: .constant(1), isScanning: .constant(false)) {} orderCard: {}
            .previewGroup(devices: [.iPhone7, .iPhone12ProMax], withZoomed: false)
    }
}

// MARK: - Rich text formatter

private struct TangemRichTextFormatter {
    // Formatting rich text as NSAttributedString
    // Supported formats: **bold**
    func format(_ string: String, fontSize: CGFloat) -> NSAttributedString {
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

            // UIKit's .semibold corresponds SwiftUI bold font
            let boldFont = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
            let boldTextRange = NSRange(location: match.range.location, length: match.range.length - 2 * formatterTagLength)
            attributedString.addAttribute(.font, value: boldFont, range: boldTextRange)
        }

        return attributedString
    }
}
