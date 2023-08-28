//
//  WarningListView.swift
//  Tangem
//
//  Created by Andrew Son on 23/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct WarningListView: View {
    var warnings: WarningsContainer
    var warningButtonAction: (Int, WarningPriority, WarningView.WarningButton) -> Void
    var spacing: CGFloat = 10

    private let transition = AnyTransition.scale.combined(with: .opacity)

    var body: some View {
        Group {
            ForEach(Array(warnings.criticals.enumerated()), id: \.element.id) { i, item in
                WarningView(warning: warnings.criticals[i], buttonAction: { b in
                    buttonAction(at: i, priority: .critical, button: b)
                })
                .transition(transition)
            }
            ForEach(Array(warnings.warnings.enumerated()), id: \.element.id) { i, item in
                WarningView(warning: warnings.warnings[i], buttonAction: { b in
                    buttonAction(at: i, priority: .warning, button: b)
                })
                .transition(transition)
            }
            ForEach(Array(warnings.infos.enumerated()), id: \.element.id) { i, item in
                WarningView(warning: warnings.infos[i], buttonAction: { b in
                    buttonAction(at: i, priority: .info, button: b)
                })
                .transition(transition)
            }
        }
    }

    private func buttonAction(at index: Int, priority: WarningPriority, button: WarningView.WarningButton) {
        withAnimation {
            warningButtonAction(index, priority, button)
        }
    }
}

struct WarningListView_Previews: PreviewProvider {
    static let container: WarningsContainer = .init(
        criticals: [AppWarning(title: "Warning", message: "Blockchain is currently unavailable", priority: .critical, type: .permanent)],
        warnings: [AppWarning(title: "Attention!", message: "Something huuuuuge is going to happen!", priority: .warning, type: .permanent)],
        infos: [AppWarning(title: "Good news, everyone!", message: "New Tangem Cards available. Visit our web site to learn more", priority: .info, type: .temporary)]
    )

    @ObservedObject static var warnings: WarningsContainer = container
    static var previews: some View {
        ScrollView {
            WarningListView(warnings: warnings, warningButtonAction: { index, priority, button in
                warningButtonAction(at: index, priority: priority)
            })
        }
    }

    static func warningButtonAction(at index: Int, priority: WarningPriority) {
        let warning: AppWarning
        switch priority {
        case .info:
            warning = warnings.infos[index]
        case .critical:
            warning = warnings.criticals[index]
        case .warning:
            warning = warnings.warnings[index]
        }

        container.remove(warning)
    }
}
